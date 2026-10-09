using System.Media;
using System.Threading;
using System.Windows;
using System.Windows.Threading;
using CharacterEfficiencyIsland.Windows.Core;
using CharacterEfficiencyIsland.Windows.Interop;
using CharacterEfficiencyIsland.Windows.Services;
using CharacterEfficiencyIsland.Windows.Views;
using Forms = System.Windows.Forms;

namespace CharacterEfficiencyIsland.Windows;

public partial class App : System.Windows.Application
{
    private Mutex? _singleInstance;
    private AppState? _state;
    private RawInputMonitor? _inputMonitor;
    private CodexWatcher? _codexWatcher;
    private TrayIconService? _tray;
    private ICharacterSurface? _surface;
    private ControlPanelWindow? _panel;
    private DispatcherTimer? _timer;
    private int _codexTick;
    private bool _exiting;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        ShutdownMode = ShutdownMode.OnExplicitShutdown;
        var profile = ProfileLoader.Load();
        _singleInstance = new Mutex(true, $"Local\\{profile.MutexId}.{BuildFlavor.Value}", out var createdNew);
        if (!createdNew)
        {
            System.Windows.MessageBox.Show(
                $"{profile.AppName} 已经在运行。请检查任务栏右侧的托盘隐藏区。",
                // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
                profile.AppName,
                MessageBoxButton.OK,
                MessageBoxImage.Information);
            Shutdown();
            return;
        }

        var store = new LocalStore(profile, BuildFlavor.Value);
        _state = new AppState(profile, store);
        _surface = BuildFlavor.Value == "companion"
            ? new CompanionWindow(_state, ShowPanelAtCursor)
            : new IslandWindow(_state);
        _panel = new ControlPanelWindow(_state, _surface, Quit);
        _tray = new TrayIconService(profile, point => _panel.ToggleAt(point), Quit);
        _codexWatcher = new CodexWatcher(_state);

        _state.Changed += (_, _) => Dispatcher.Invoke(RefreshWindows);
        _state.NotificationRaised += (_, detail) => Dispatcher.Invoke(() =>
        {
            SystemSounds.Asterisk.Play();
            _tray?.Notify(_state.DisplayTitle, detail);
            RefreshWindows();
        });

        _inputMonitor = new RawInputMonitor(_state.Profile.StorageId);
        _inputMonitor.Faulted += (_, detail) => Dispatcher.BeginInvoke(() =>
        {
            if (_state is null)
            {
                return;
            }
            _state.InputStatus = detail;
            RefreshWindows();
        });
        _inputMonitor.InputCaptured += (_, input) => _state.RecordInput(input);
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        var inputStarted = _inputMonitor.Start();
        _state.InputStatus = inputStarted
            ? "输入监测已启用：只记录按键类别、数量和鼠标点击，不保存输入内容"
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            : _inputMonitor.LastError ?? "输入监测启动失败；计时和提醒仍可使用，但 APM/EPM 不会完整";

        _timer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromSeconds(1)
        };
        _timer.Tick += TimerOnTick;
        _timer.Start();

        RefreshWindows();
        if (_state.Settings.ShowPersistentSurface)
        {
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            _surface.ShowSurface();
        }

        if (!_state.Settings.FirstLaunchPanelShown && !e.Args.Contains("--startup", StringComparer.OrdinalIgnoreCase))
        {
            _state.Settings.FirstLaunchPanelShown = true;
            _state.SaveAll();
            var firstOpen = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(700) };
            firstOpen.Tick += (_, _) =>
            {
                firstOpen.Stop();
                ShowPanelAtCursor();
            };
            firstOpen.Start();
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        if (!_exiting)
        {
            Cleanup();
        }
        base.OnExit(e);
    }

    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private async void TimerOnTick(object? sender, EventArgs e)
    {
        if (_state is null)
        {
            return;
        }
        _state.Tick(IdleMonitor.CurrentIdleTime());
        _codexTick++;
        if (_codexTick >= 5)
        {
            _codexTick = 0;
            if (_panel?.AiRemindersEnabled == true && _codexWatcher is not null)
            {
                await _codexWatcher.PollAsync();
            }
        }
    }

    private void RefreshWindows()
    {
        if (_state is null)
        {
            return;
        }
        _surface?.Refresh(_state);
        _panel?.Refresh();
    }

    private void ShowPanelAtCursor()
    {
        _panel?.ShowAt(Forms.Cursor.Position);
    }

    private void Quit()
    {
        if (_exiting)
        {
            return;
        }
        _exiting = true;
        _panel?.CloseForExit();
        if (_surface is Window surfaceWindow)
        {
            surfaceWindow.Hide();
            surfaceWindow.Close();
        }
        Cleanup();
        Shutdown(0);
    }

    private void Cleanup()
    {
        _timer?.Stop();
        _state?.SaveAll();
        _inputMonitor?.Dispose();
        _tray?.Dispose();
        _singleInstance?.ReleaseMutex();
        _singleInstance?.Dispose();
    }
}
