using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace CharacterEfficiencyIsland.Windows.Interop;

internal static class ScreenGeometry
{
    public static Forms.Screen FindScreen(string? deviceName) =>
        Forms.Screen.AllScreens.FirstOrDefault(screen =>
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            string.Equals(screen.DeviceName, deviceName, StringComparison.OrdinalIgnoreCase))
        ?? Forms.Screen.PrimaryScreen
        ?? Forms.Screen.AllScreens[0];

    public static Forms.Screen FromPoint(Drawing.Point point) => Forms.Screen.FromPoint(point);

    public static double ScaleAt(Drawing.Point point)
    {
        var monitor = MonitorFromPoint(new NativePoint(point.X, point.Y), 2);
        if (monitor != IntPtr.Zero && GetDpiForMonitor(monitor, 0, out var dpiX, out _) == 0 && dpiX > 0)
        {
            return dpiX / 96.0;
        }
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        return 1.0;
    }

    public static void SetPosition(Window window, double pixelX, double pixelY, Forms.Screen screen)
    {
        var center = new Drawing.Point(
            screen.WorkingArea.Left + screen.WorkingArea.Width / 2,
            screen.WorkingArea.Top + screen.WorkingArea.Height / 2);
        var scale = ScaleAt(center);
        window.Left = pixelX / scale;
        window.Top = pixelY / scale;
    }

    public static double WindowPixelWidth(Window window, Forms.Screen screen)
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    {
        var center = new Drawing.Point(
            screen.WorkingArea.Left + screen.WorkingArea.Width / 2,
            screen.WorkingArea.Top + screen.WorkingArea.Height / 2);
        return window.Width * ScaleAt(center);
    }

    public static double WindowPixelHeight(Window window, Forms.Screen screen)
    {
        var center = new Drawing.Point(
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            screen.WorkingArea.Left + screen.WorkingArea.Width / 2,
            screen.WorkingArea.Top + screen.WorkingArea.Height / 2);
        return window.Height * ScaleAt(center);
    }

    public static void EnsureHandle(Window window) => _ = new WindowInteropHelper(window).EnsureHandle();

    [StructLayout(LayoutKind.Sequential)]
    private readonly struct NativePoint
    {
        public NativePoint(int x, int y)
        {
            X = x;
            Y = y;
        }
        public int X { get; }
        public int Y { get; }
    }

    [DllImport("user32.dll")]
    private static extern IntPtr MonitorFromPoint(NativePoint point, uint flags);

    [DllImport("shcore.dll")]
    private static extern int GetDpiForMonitor(IntPtr monitor, int dpiType, out uint dpiX, out uint dpiY);
}
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
