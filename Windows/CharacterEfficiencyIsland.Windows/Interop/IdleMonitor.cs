// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
using System.Runtime.InteropServices;

namespace CharacterEfficiencyIsland.Windows.Interop;

internal static class IdleMonitor
{
    public static TimeSpan CurrentIdleTime()
    {
        var info = new LastInputInfo { Size = (uint)Marshal.SizeOf<LastInputInfo>() };
        if (!GetLastInputInfo(ref info))
        {
            return TimeSpan.Zero;
        }
        var elapsed = unchecked(GetTickCount() - info.Time);
        return TimeSpan.FromMilliseconds(elapsed);
    }

    [StructLayout(LayoutKind.Sequential)]
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private struct LastInputInfo
    {
        public uint Size;
        public uint Time;
    }

    [DllImport("user32.dll")]
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    [return: MarshalAs(UnmanagedType.Bool)]
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private static extern bool GetLastInputInfo(ref LastInputInfo info);

    [DllImport("kernel32.dll")]
    private static extern uint GetTickCount();
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
}
