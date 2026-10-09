using System.Windows;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using CharacterEfficiencyIsland.Windows.Core;
using CharacterEfficiencyIsland.Windows.Interop;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace CharacterEfficiencyIsland.Windows.Views;

public partial class ControlPanelWindow : Window
{
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private const double BasePanelWidth = 520;
    private const double BasePanelHeight = 500;
    private const double MinimumPanelScale = 0.65;
    private const double MaximumPanelScale = 1.60;

    private sealed record ReminderControls(
        System.Windows.Controls.CheckBox Enabled,
        System.Windows.Controls.TextBox Title,
        System.Windows.Controls.TextBox Schedule);

    private readonly AppState _state;
    private readonly ICharacterSurface _surface;
    private readonly Action _quit;
    private readonly Dictionary<string, ReminderControls> _reminderControls = new();
    private double _panelScale;
    private Drawing.Point _trayAnchor;
    private bool _refreshing;
    private bool _allowClose;
    private string StartupEntryName => $"{_state.Profile.AppName} · {(BuildFlavor.Value == "companion" ? "桌宠" : "灵动岛")}";

    public ControlPanelWindow(AppState state, ICharacterSurface surface, Action quit)
    {
        _state = state;
        _surface = surface;
        _quit = quit;
        _trayAnchor = Forms.Cursor.Position;
        var savedPanelScale = BuildFlavor.Value == "companion"
            ? state.Settings.CompanionPanelScale
            : state.Settings.DynamicIslandPanelScale;
        _panelScale = Math.Clamp(savedPanelScale, MinimumPanelScale, MaximumScaleForCurrentScreen());
        InitializeComponent();
        ApplyPanelScale();
        SourceInitialized += (_, _) => WindowMaterial.ApplyAcrylic(
            this,
            unchecked((int)0x22505050),
            () => 24 * _panelScale);
        BuildReminderRows();
        Closing += (_, args) =>
        {
            if (!_allowClose)
            {
                args.Cancel = true;
                Hide();
            }
        };
        Deactivated += (_, _) => SaveReminderRows();
        Refresh();
    }

    public bool AiRemindersEnabled => _state.Settings.AiRemindersEnabled;

    public void ToggleAt(Drawing.Point trayPoint)
    {
        if (IsVisible)
        {
            Hide();
            return;
        }
        ShowAt(trayPoint);
    }

    public void ShowAt(Drawing.Point trayPoint)
    {
        _trayAnchor = trayPoint;
        _panelScale = Math.Clamp(_panelScale, MinimumPanelScale, MaximumScaleForCurrentScreen());
        ApplyPanelScale();
        SaveReminderRows();
        Refresh();
        if (!IsVisible)
        {
            Show();
        }
        PositionAgainstTaskbar(trayPoint);
        Activate();
        Topmost = true;
    }

    public void Refresh()
    {
        _refreshing = true;
        try
        {
            var mode = _state.DisplayMode;
            ModeTitle.Text = _state.DisplayTitle;
            ModeSubtitle.Text = _state.DisplayDetail;
            WorkLabel.Text = $"工作 {_state.FormatSeconds(_state.WorkSeconds)}";
            BreakLabel.Text = $"休息 {_state.FormatSeconds(_state.BreakSeconds)}";
            AiLabel.Text = $"AI 完成 {_state.AiDoneCount}";
            IdleLabel.Text = $"当前状态：{(_state.IsPaused ? "已暂停" : _state.Profile.Title(_state.Mode))}";
            TodayLabel.Text = $"今天 工作 {_state.FormatSeconds(_state.WorkSeconds)} · 休息 {_state.FormatSeconds(_state.BreakSeconds)} · 水 {_state.WaterCheckins} · AI {_state.AiDoneCount}";
            var total = _state.TotalRecord;
            TotalLabel.Text = $"累计 {_state.ActiveRecordDays} 天 · 工作 {_state.FormatSeconds(total.WorkSeconds)} · 字 {total.PrintableKeys} · 水 {total.WaterCheckins} · AI {total.AiDoneCount}";

            TypingLabel.Text = $"打字量 {_state.TotalPrintableKeys}";
            RawSpeedLabel.Text = $"当前 {_state.CurrentRawSpeed}/min";
            CorrectionLabel.Text = $"修正率 {_state.CorrectionRate}%";
            AverageSpeedLabel.Text = $"均速 {_state.AverageEffectiveSpeed}/min";
            ApmLabel.Text = $"APM {_state.CurrentApm}/min";
            EpmLabel.Text = $"EPM {_state.CurrentEpm}/min";
            InputStatusLabel.Text = _state.InputStatus;
            CodexStatusLabel.Text = _state.CodexStatus;
            ScaleLabel.Text = $"灵动岛大小 {Math.Round(_state.Settings.SurfaceScale * 100):0}%";

            AiReminderCheck.IsChecked = _state.Settings.AiRemindersEnabled;
            SurfaceCheck.IsChecked = _state.Settings.ShowPersistentSurface;
            StartupCheck.IsChecked = StartupManager.IsEnabled(StartupEntryName);

            foreach (var reminder in _state.Reminders)
            {
                if (!_reminderControls.TryGetValue(reminder.Id, out var controls))
                {
                    continue;
                }
                controls.Enabled.IsChecked = reminder.Enabled;
                if (!controls.Title.IsKeyboardFocusWithin)
                {
                    controls.Title.Text = reminder.Title;
                }
                if (!controls.Schedule.IsKeyboardFocusWithin)
                {
                    controls.Schedule.Text = reminder.Schedule;
                }
            }

            PanelImage.Source = AssetLoader.Image(_state.Profile.PanelAsset(mode));
            var placement = _state.Profile.Placement(mode);
            PanelImage.Height = placement.Height;
            PanelImage.Margin = new Thickness(0, 0, placement.Right, placement.Bottom);
        }
        finally
        {
            _refreshing = false;
        }
    }

    public void CloseForExit()
    {
        _allowClose = true;
        Close();
    }

    private void BuildReminderRows()
    {
        foreach (var reminder in _state.Reminders)
        {
            var row = new Grid { Margin = new Thickness(0, 1, 0, 1) };
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(24) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) });
            row.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(105) });

            var enabled = new System.Windows.Controls.CheckBox
            {
                IsChecked = reminder.Enabled,
                VerticalAlignment = VerticalAlignment.Center
            };
            var title = new System.Windows.Controls.TextBox
            {
                Text = reminder.Title,
                IsReadOnly = reminder.Id == "water"
            };
            var schedule = new System.Windows.Controls.TextBox { Text = reminder.Schedule };
            Grid.SetColumn(enabled, 0);
            Grid.SetColumn(title, 1);
            Grid.SetColumn(schedule, 2);
            row.Children.Add(enabled);
            row.Children.Add(title);
            row.Children.Add(schedule);
            ReminderRows.Children.Add(row);
            _reminderControls[reminder.Id] = new ReminderControls(enabled, title, schedule);

            enabled.Checked += ReminderControl_OnChanged;
            enabled.Unchecked += ReminderControl_OnChanged;
            title.LostKeyboardFocus += ReminderControl_OnChanged;
            schedule.LostKeyboardFocus += ReminderControl_OnChanged;
        }
    }

    private void SaveReminderRows()
    {
        if (_refreshing)
        {
            return;
        }
        foreach (var reminder in _state.Reminders)
        {
            if (_reminderControls.TryGetValue(reminder.Id, out var controls))
            {
                _state.UpdateReminder(
                    reminder.Id,
                    controls.Enabled.IsChecked == true,
                    controls.Title.Text,
                    controls.Schedule.Text);
            }
        }
    }

    private void ReminderControl_OnChanged(object sender, RoutedEventArgs e) => SaveReminderRows();

    private void OptionCheck_OnChanged(object sender, RoutedEventArgs e)
    {
        if (_refreshing)
        {
            return;
        }
        _state.SetAiRemindersEnabled(AiReminderCheck.IsChecked == true);
        _state.SetSurfaceVisible(SurfaceCheck.IsChecked == true);
    }

    private void StartupCheck_OnChanged(object sender, RoutedEventArgs e)
    {
        if (_refreshing)
        {
            return;
        }
        var wanted = StartupCheck.IsChecked == true;
        if (!StartupManager.SetEnabled(StartupEntryName, wanted))
        {
            System.Windows.MessageBox.Show(
                "没有成功修改 Windows 启动项。请确认当前安装位置可长期使用后再试。",
                _state.Profile.AppName,
                MessageBoxButton.OK,
                MessageBoxImage.Warning);
            _refreshing = true;
            StartupCheck.IsChecked = StartupManager.IsEnabled(StartupEntryName);
            _refreshing = false;
        }
    }

    private void StartBreak_OnClick(object sender, RoutedEventArgs e) => _state.StartBreak();
    private void EndBreak_OnClick(object sender, RoutedEventArgs e) => _state.EndBreak();
    private void TogglePause_OnClick(object sender, RoutedEventArgs e) => _state.TogglePause();
    private void Water_OnClick(object sender, RoutedEventArgs e) => _state.CheckInWater();
    private void ResetScale_OnClick(object sender, RoutedEventArgs e) => _surface.ResetScale();
    private void OpenRecords_OnClick(object sender, RoutedEventArgs e) => _state.OpenRecordFolder();

    private void ResetToday_OnClick(object sender, RoutedEventArgs e)
    {
        if (Confirm("确定清零今天的记录吗？")) _state.ResetToday();
    }

    private void ResetAll_OnClick(object sender, RoutedEventArgs e)
    {
        if (Confirm("确定清空全部本地记录吗？此操作无法撤销。")) _state.ResetAll();
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    }

    private bool Confirm(string text) => System.Windows.MessageBox.Show(
        text,
        _state.Profile.AppName,
        MessageBoxButton.YesNo,
        MessageBoxImage.Question) == MessageBoxResult.Yes;

    private void Quit_OnClick(object sender, RoutedEventArgs e) => _quit();
    private void CloseButton_OnClick(object sender, RoutedEventArgs e) => Hide();

    private void Header_OnMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.LeftButton == MouseButtonState.Pressed)
        {
            DragMove();
        }
    }

    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private void PanelResize_OnDragDelta(object sender, DragDeltaEventArgs e)
    {
        var edge = (sender as FrameworkElement)?.Tag?.ToString() ?? "";
        var horizontal = edge.Contains("Left", StringComparison.Ordinal)
            ? -e.HorizontalChange
            : edge.Contains("Right", StringComparison.Ordinal) ? e.HorizontalChange : 0;
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        var vertical = edge.Contains("Top", StringComparison.Ordinal)
            ? -e.VerticalChange
            : edge.Contains("Bottom", StringComparison.Ordinal) ? e.VerticalChange : 0;
        var horizontalScale = horizontal / BasePanelWidth;
        var verticalScale = vertical / BasePanelHeight;
        var change = Math.Abs(horizontalScale) >= Math.Abs(verticalScale)
            ? horizontalScale
            : verticalScale;
        _panelScale = Math.Clamp(
            _panelScale + change,
            MinimumPanelScale,
            MaximumScaleForCurrentScreen());
        ApplyPanelScale();
    }

    private void PanelResize_OnDragCompleted(object sender, DragCompletedEventArgs e)
    {
        _state.SetPanelScale(_panelScale, BuildFlavor.Value == "companion");
        PositionAgainstTaskbar(_trayAnchor);
    }

    private void ApplyPanelScale()
    {
        Width = BasePanelWidth * _panelScale;
        Height = BasePanelHeight * _panelScale;
    }

    private double MaximumScaleForCurrentScreen()
    {
        var screen = Forms.Screen.FromPoint(_trayAnchor);
        var scale = ScreenGeometry.ScaleAt(_trayAnchor);
        var availableWidth = screen.WorkingArea.Width / scale - 16;
        var availableHeight = screen.WorkingArea.Height / scale - 16;
        return Math.Max(
            MinimumPanelScale,
            Math.Min(MaximumPanelScale, Math.Min(
                availableWidth / BasePanelWidth,
                availableHeight / BasePanelHeight)));
    }

    private void PositionAgainstTaskbar(Drawing.Point trayPoint)
    {
        var screen = Forms.Screen.FromPoint(trayPoint);
        var bounds = screen.Bounds;
        var area = screen.WorkingArea;
        var scale = ScreenGeometry.ScaleAt(trayPoint);
        var width = Width * scale;
        var height = Height * scale;
        var taskbarTop = area.Top > bounds.Top;
        var taskbarBottom = area.Bottom < bounds.Bottom;
        var taskbarLeft = area.Left > bounds.Left;
        var taskbarRight = area.Right < bounds.Right;

        double x;
        double y;
        if (taskbarLeft)
        {
            x = area.Left;
            y = Math.Clamp(trayPoint.Y - height / 2, area.Top, Math.Max(area.Top, area.Bottom - height));
        }
        else if (taskbarRight)
        {
            x = area.Right - width;
            y = Math.Clamp(trayPoint.Y - height / 2, area.Top, Math.Max(area.Top, area.Bottom - height));
        }
        else
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        {
            x = Math.Clamp(trayPoint.X - width / 2, area.Left, Math.Max(area.Left, area.Right - width));
            y = taskbarTop ? area.Top : area.Bottom - height;
            if (!taskbarTop && !taskbarBottom)
            {
                y = area.Bottom - height;
            }
        }
        ScreenGeometry.SetPosition(this, x, y, screen);
    }
}
