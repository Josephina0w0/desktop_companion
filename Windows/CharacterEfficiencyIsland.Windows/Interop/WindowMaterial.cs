using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;

namespace CharacterEfficiencyIsland.Windows.Interop;

// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
internal static class WindowMaterial
{
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private const int DwmwaWindowCornerPreference = 33;
    private const int DwmwaBorderColor = 34;
    private const int DwmWindowCornerDoNotRound = 1;
    private const int DwmColorNone = unchecked((int)0xFFFFFFFE);
    public static void ApplyAcrylic(Window window, int tintColor, Func<double> cornerRadius)
    {
        var handle = new WindowInteropHelper(window).EnsureHandle();
        if (HwndSource.FromHwnd(handle) is HwndSource source)
        {
            source.CompositionTarget.BackgroundColor = Colors.Transparent;
        }

        var corners = DwmWindowCornerDoNotRound;
        _ = DwmSetWindowAttribute(
            handle,
            DwmwaWindowCornerPreference,
            ref corners,
            Marshal.SizeOf<int>());

        var borderColor = DwmColorNone;
        _ = DwmSetWindowAttribute(
            handle,
            DwmwaBorderColor,
            ref borderColor,
            Marshal.SizeOf<int>());

        void UpdateRegion(object? sender = null, SizeChangedEventArgs? args = null) =>
            SetRoundedRegion(window, handle, cornerRadius());

        window.SizeChanged += UpdateRegion;
        window.Dispatcher.BeginInvoke((Action)(() => UpdateRegion()));
    }

    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private static void SetRoundedRegion(Window window, IntPtr handle, double radius)
    {
        var dpi = VisualTreeHelper.GetDpi(window);
        var width = Math.Max(1, (int)Math.Ceiling(window.ActualWidth * dpi.DpiScaleX));
        var height = Math.Max(1, (int)Math.Ceiling(window.ActualHeight * dpi.DpiScaleY));
        var diameter = Math.Max(1, (int)Math.Round(radius * 2 * dpi.DpiScaleX));
        var region = CreateRoundRectRgn(0, 0, width + 1, height + 1, diameter, diameter);
        if (region == IntPtr.Zero)
        {
            return;
        }

        if (SetWindowRgn(handle, region, true) == 0)
        {
            _ = DeleteObject(region);
        }
    }

    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(
        IntPtr window,
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        int attribute,
        ref int value,
        int valueSize);

    [DllImport("gdi32.dll")]
    private static extern IntPtr CreateRoundRectRgn(
        int left,
        int top,
        int right,
        int bottom,
        int ellipseWidth,
        int ellipseHeight);

    [DllImport("user32.dll")]
    private static extern int SetWindowRgn(IntPtr window, IntPtr region, bool redraw);

    [DllImport("gdi32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool DeleteObject(IntPtr handle);
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
}
