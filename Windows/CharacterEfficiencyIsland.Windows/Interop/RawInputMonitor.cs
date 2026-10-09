using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Interop;
using CharacterEfficiencyIsland.Windows.Core;

namespace CharacterEfficiencyIsland.Windows.Interop;

internal sealed class RawInputMonitor : IDisposable
{
    private const int WmInput = 0x00FF;
    private const uint RidInput = 0x10000003;
    private const uint RidevInputSink = 0x00000100;
    private const uint RimTypeMouse = 0;
    private const uint RimTypeKeyboard = 1;
    private const ushort RiKeyBreak = 0x0001;
    private const ushort MouseLeftDown = 0x0001;
    private const ushort MouseRightDown = 0x0004;
    private const ushort MouseMiddleDown = 0x0010;
    private const ushort MouseButton4Down = 0x0040;
    private const ushort MouseButton5Down = 0x0100;
    private const uint MaximumRawInputPacketSize = 64 * 1024;

    private readonly HashSet<ushort> _pressedKeys = new();
    private readonly string _diagnosticPath;
    private HwndSource? _source;
    private bool _disposed;
    private DateTimeOffset _lastFaultWrittenAt;

    public event EventHandler<InputAction>? InputCaptured;
    public event EventHandler<string>? Faulted;
    public bool IsActive { get; private set; }
    public string? LastError { get; private set; }

    public RawInputMonitor(string storageId)
    {
        _diagnosticPath = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            storageId,
            "Diagnostics",
            "raw-input-errors.log");
    }

    public bool Start()
    {
        if (_disposed)
        {
            return false;
        }
        if (_source is not null)
        {
            return IsActive;
        }

        try
        {
            var parameters = new HwndSourceParameters("CharacterEfficiencyIsland.RawInput")
            {
                Width = 1,
                Height = 1,
                WindowStyle = unchecked((int)0x80000000)
            };
            _source = new HwndSource(parameters);
            _source.AddHook(WindowHook);

            var devices = new[]
            {
                new RawInputDevice
                // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
                {
                    UsagePage = 0x01,
                    Usage = 0x06,
                    Flags = RidevInputSink,
                    Target = _source.Handle
                },
                new RawInputDevice
                {
                    UsagePage = 0x01,
                    Usage = 0x02,
                    Flags = RidevInputSink,
                    Target = _source.Handle
                }
            };

            IsActive = RegisterRawInputDevices(
                devices,
                (uint)devices.Length,
                (uint)Marshal.SizeOf<RawInputDevice>());
            if (!IsActive)
            {
                ReportFault("RegisterRawInputDevices", new Win32Exception(Marshal.GetLastWin32Error()));
                ReleaseSource();
            }
            return IsActive;
        }
        catch (Exception error)
        {
            IsActive = false;
            ReportFault("Start", error);
            ReleaseSource();
            return false;
        }
    }

    public void Dispose()
    {
        if (_disposed)
        {
            return;
        }
        _disposed = true;
        IsActive = false;
        ReleaseSource();
        _pressedKeys.Clear();
    }

    private IntPtr WindowHook(IntPtr hwnd, int message, IntPtr wParam, IntPtr lParam, ref bool handled)
    {
        if (message == WmInput && IsActive && !_disposed)
        {
            try
            {
                ReadInput(lParam);
            }
            catch (Exception error)
            {
                ReportFault("WM_INPUT", error);
            }
        }
        return IntPtr.Zero;
    }

    private void ReadInput(IntPtr rawInputHandle)
    {
        uint size = 0;
        var headerSize = (uint)Marshal.SizeOf<RawInputHeader>();
        if (GetRawInputData(rawInputHandle, RidInput, IntPtr.Zero, ref size, headerSize) == uint.MaxValue ||
            size < headerSize || size > MaximumRawInputPacketSize)
        {
            return;
        }

        var buffer = Marshal.AllocHGlobal((int)size);
        try
        {
            var copied = GetRawInputData(rawInputHandle, RidInput, buffer, ref size, headerSize);
            if (copied == uint.MaxValue || copied < headerSize || copied > MaximumRawInputPacketSize)
            {
                return;
            }

            var header = Marshal.PtrToStructure<RawInputHeader>(buffer);
            if (header.Size < headerSize || header.Size > copied)
            {
                return;
            }

            var dataSize = copied - headerSize;
            var data = IntPtr.Add(buffer, checked((int)headerSize));
            if (header.Type == RimTypeKeyboard && dataSize >= (uint)Marshal.SizeOf<RawKeyboard>())
            {
                HandleKeyboard(Marshal.PtrToStructure<RawKeyboard>(data));
            }
            else if (header.Type == RimTypeMouse && dataSize >= (uint)Marshal.SizeOf<RawMouse>())
            {
                HandleMouse(Marshal.PtrToStructure<RawMouse>(data));
            }
        }
        finally
        {
            Marshal.FreeHGlobal(buffer);
        }
    }

    private void HandleKeyboard(RawKeyboard keyboard)
    {
        var key = keyboard.VirtualKey;
        if (key == 0 || key == 0xFF)
        {
            return;
        }

        if ((keyboard.Flags & RiKeyBreak) != 0)
        {
            _pressedKeys.Remove(key);
            return;
        }

        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        var isRepeat = !_pressedKeys.Add(key);
        var isCorrection = key is 0x08 or 0x2E;
        var isPrintable = IsPrintableKey(key) && !HasCommandModifier();
        Publish(new InputAction(true, key, isCorrection, isPrintable, isRepeat));
    }

    private void HandleMouse(RawMouse mouse)
    {
        var flags = mouse.ButtonFlags;
        var clicks = 0;
        if ((flags & MouseLeftDown) != 0) clicks++;
        if ((flags & MouseRightDown) != 0) clicks++;
        if ((flags & MouseMiddleDown) != 0) clicks++;
        if ((flags & MouseButton4Down) != 0) clicks++;
        if ((flags & MouseButton5Down) != 0) clicks++;

        for (var index = 0; index < clicks; index++)
        {
            Publish(new InputAction(false, 0, false, false, false));
        }
    }

    private void Publish(InputAction input)
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    {
        try
        {
            InputCaptured?.Invoke(this, input);
        }
        catch (Exception error)
        {
            ReportFault("InputCaptured", error);
        }
    }

    private void ReleaseSource()
    {
        if (_source is null)
        {
            return;
        }
        try
        {
            _source.RemoveHook(WindowHook);
            _source.Dispose();
        }
        catch (Exception error)
        {
            ReportFault("Dispose", error);
        }
        finally
        {
            _source = null;
        }
    }

    private void ReportFault(string stage, Exception error)
    {
        var message = $"输入监测遇到 {error.GetType().Name}，已跳过异常输入；应用会继续运行";
        LastError = message;
        var now = DateTimeOffset.Now;
        var shouldReport = now - _lastFaultWrittenAt >= TimeSpan.FromSeconds(1);
        if (shouldReport)
        {
            _lastFaultWrittenAt = now;
            try
            {
                var folder = Path.GetDirectoryName(_diagnosticPath);
                if (!string.IsNullOrWhiteSpace(folder))
                {
                    Directory.CreateDirectory(folder);
                }
                File.AppendAllText(
                    _diagnosticPath,
                    $"[{now:O}] {stage}: {error}\n\n");
            }
            catch
            {
                // Diagnostics must never become another failure path.
            }
        }

        if (!shouldReport)
        {
            return;
        }

        try
        {
            Faulted?.Invoke(this, message);
        }
        catch
        {
            // A status listener must not escape the native window callback either.
        }
    }

    private bool HasCommandModifier() =>
        _pressedKeys.Contains(0x11) || _pressedKeys.Contains(0xA2) || _pressedKeys.Contains(0xA3) ||
        _pressedKeys.Contains(0x12) || _pressedKeys.Contains(0xA4) || _pressedKeys.Contains(0xA5) ||
        _pressedKeys.Contains(0x5B) || _pressedKeys.Contains(0x5C);

    private static bool IsPrintableKey(ushort key) =>
        key is >= 0x30 and <= 0x5A ||
        key is >= 0x60 and <= 0x6F ||
        key == 0x20 ||
        key is >= 0xBA and <= 0xC0 ||
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        key is >= 0xDB and <= 0xDF;

    [StructLayout(LayoutKind.Sequential)]
    private struct RawInputDevice
    {
        public ushort UsagePage;
        public ushort Usage;
        public uint Flags;
        public IntPtr Target;
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct RawInputHeader
    {
        public uint Type;
        public uint Size;
        public IntPtr Device;
        public IntPtr WParam;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct RawKeyboard
    {
        public ushort MakeCode;
        public ushort Flags;
        public ushort Reserved;
        public ushort VirtualKey;
        public uint Message;
        public uint ExtraInformation;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct RawMouse
    {
        [FieldOffset(0)] public ushort Flags;
        [FieldOffset(4)] public uint Buttons;
        [FieldOffset(4)] public ushort ButtonFlags;
        [FieldOffset(6)] public ushort ButtonData;
        [FieldOffset(8)] public uint RawButtons;
        [FieldOffset(12)] public int LastX;
        [FieldOffset(16)] public int LastY;
        [FieldOffset(20)] public uint ExtraInformation;
    }

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool RegisterRawInputDevices(
        [In] RawInputDevice[] devices,
        uint deviceCount,
        uint size);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint GetRawInputData(
        IntPtr rawInput,
        uint command,
        IntPtr data,
        ref uint size,
        uint headerSize);
}
