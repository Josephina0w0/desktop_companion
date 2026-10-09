using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Drawing = System.Drawing;

namespace CharacterEfficiencyIsland.Windows.Core;

internal static class AssetLoader
{
    private static readonly Dictionary<string, ImageSource> Cache = new(StringComparer.OrdinalIgnoreCase);

    public static ImageSource Image(string assetName)
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    {
        if (Cache.TryGetValue(assetName, out var cached))
        {
            return cached;
        }

        var uri = new Uri($"pack://application:,,,/Assets/{assetName}.png", UriKind.Absolute);
        var image = new BitmapImage();
        image.BeginInit();
        image.UriSource = uri;
        image.CacheOption = BitmapCacheOption.OnLoad;
        image.EndInit();
        image.Freeze();
        var prepared = RemoveConnectedNearWhiteBackground(image);
        Cache[assetName] = prepared;
        return prepared;
    }

    public static Drawing.Icon TrayIcon()
    {
        var resource = System.Windows.Application.GetResourceStream(
            new Uri("pack://application:,,,/Assets/statusIcon.png", UriKind.Absolute));
        if (resource is null)
        {
            return (Drawing.Icon)Drawing.SystemIcons.Application.Clone();
        }

        using var source = new Drawing.Bitmap(resource.Stream);
        const int iconSize = 64;
        const int inset = 2;
        using var bitmap = new Drawing.Bitmap(
            iconSize,
            iconSize,
            Drawing.Imaging.PixelFormat.Format32bppArgb);
        using (var graphics = Drawing.Graphics.FromImage(bitmap))
        {
            graphics.Clear(Drawing.Color.Transparent);
            graphics.CompositingMode = Drawing.Drawing2D.CompositingMode.SourceCopy;
            graphics.CompositingQuality = Drawing.Drawing2D.CompositingQuality.HighQuality;
            graphics.InterpolationMode = Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = Drawing.Drawing2D.PixelOffsetMode.HighQuality;
            graphics.SmoothingMode = Drawing.Drawing2D.SmoothingMode.HighQuality;

            var available = iconSize - inset * 2;
            var scale = Math.Min(available / (double)source.Width, available / (double)source.Height);
            var width = Math.Max(1, (int)Math.Round(source.Width * scale));
            var height = Math.Max(1, (int)Math.Round(source.Height * scale));
            var left = (iconSize - width) / 2;
            var top = (iconSize - height) / 2;
            graphics.DrawImage(source, new Drawing.Rectangle(left, top, width, height));
        }

        var handle = bitmap.GetHicon();
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        try
        {
            using var icon = Drawing.Icon.FromHandle(handle);
            return (Drawing.Icon)icon.Clone();
        }
        finally
        {
            DestroyIcon(handle);
        }
    }

    private static ImageSource RemoveConnectedNearWhiteBackground(BitmapSource source)
    {
        var formatted = new FormatConvertedBitmap(source, PixelFormats.Bgra32, null, 0);
        var width = formatted.PixelWidth;
        var height = formatted.PixelHeight;
        var stride = width * 4;
        var pixels = new byte[stride * height];
        formatted.CopyPixels(pixels, stride, 0);

        bool IsNearWhite(int pixelIndex)
        {
            var offset = pixelIndex * 4;
            var blue = pixels[offset];
            var green = pixels[offset + 1];
            var red = pixels[offset + 2];
            var alpha = pixels[offset + 3];
            return alpha >= 245 && red >= 236 && green >= 236 && blue >= 236 &&
                Math.Max(red, Math.Max(green, blue)) - Math.Min(red, Math.Min(green, blue)) <= 12;
        }

        if (!IsNearWhite(0) && !IsNearWhite(width - 1) &&
            !IsNearWhite((height - 1) * width) && !IsNearWhite(width * height - 1))
        {
            return source;
        }

        var visited = new bool[width * height];
        var queue = new Queue<int>();
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        void EnqueueIfBackground(int index)
        {
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            if (!visited[index] && IsNearWhite(index))
            {
                visited[index] = true;
                queue.Enqueue(index);
            }
        }

        for (var x = 0; x < width; x++)
        {
            EnqueueIfBackground(x);
            EnqueueIfBackground((height - 1) * width + x);
        }
        for (var y = 0; y < height; y++)
        {
            EnqueueIfBackground(y * width);
            EnqueueIfBackground(y * width + width - 1);
        }
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).

        while (queue.TryDequeue(out var index))
        {
            pixels[index * 4 + 3] = 0;
            var x = index % width;
            var y = index / width;
            if (x > 0) EnqueueIfBackground(index - 1);
            if (x + 1 < width) EnqueueIfBackground(index + 1);
            if (y > 0) EnqueueIfBackground(index - width);
            if (y + 1 < height) EnqueueIfBackground(index + width);
        }

        var result = BitmapSource.Create(
            width,
            height,
            formatted.DpiX,
            formatted.DpiY,
            PixelFormats.Bgra32,
            null,
            pixels,
            stride);
        result.Freeze();
        return result;
    }

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DestroyIcon(IntPtr handle);
}
