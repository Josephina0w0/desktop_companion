using System.Windows;
using System.Windows.Controls.Primitives;
using System.Windows.Input;
using CharacterEfficiencyIsland.Windows.Core;
using CharacterEfficiencyIsland.Windows.Interop;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace CharacterEfficiencyIsland.Windows.Views;

public partial class CompanionWindow : Window, ICharacterSurface
{
    private const double BaseWidth = 280;
    private const double BaseHeight = 390;
    private readonly AppState _state;
    private readonly Action _openPanel;
    private double _workingScale;

    public CompanionWindow(AppState state, Action openPanel)
    {
        _state = state;
        _openPanel = openPanel;
        _workingScale = state.Settings.SurfaceScale;
        InitializeComponent();
        ApplyScale();
        SourceInitialized += (_, _) => RestorePosition();
        Refresh(state);
    }

    public void Refresh(AppState state)
    {
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        CharacterImage.Source = AssetLoader.Image(state.Profile.IslandAsset(state.DisplayMode));
        BubbleTitle.Text = state.DisplayTitle;
        BubbleDetail.Text = state.DisplayDetail;
        if (state.Settings.ShowPersistentSurface)
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        {
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            ShowSurface();
        }
        else
        {
            HideSurface();
        }
    }

    public void ShowSurface()
    {
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        if (!IsVisible)
        {
            Show();
            RestorePosition();
        }
    }

    public void HideSurface()
    {
        if (IsVisible)
        {
            Hide();
        }
    }

    public void ResetScale()
    {
        _workingScale = 1;
        _state.SetSurfaceScale(1);
        ApplyScale();
        ClampAndSavePosition();
    }

    private void Root_OnMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ClickCount == 2)
        {
            _openPanel();
            return;
        }
        try
        {
            DragMove();
            ClampAndSavePosition();
        }
        catch
        {
            // DragMove can throw if mouse capture is lost.
        }
    }

    private void ResizeThumb_OnDragStarted(object sender, DragStartedEventArgs e) =>
        _workingScale = _state.Settings.SurfaceScale;

    private void ResizeThumb_OnDragDelta(object sender, DragDeltaEventArgs e)
    {
        _workingScale = Math.Clamp(_workingScale + (e.HorizontalChange + e.VerticalChange) / BaseHeight, 0.75, 1.60);
        ApplyScale();
    }

    private void ResizeThumb_OnDragCompleted(object sender, DragCompletedEventArgs e)
    {
        _state.SetSurfaceScale(_workingScale);
        ClampAndSavePosition();
    }

    private void ApplyScale()
    {
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        Width = BaseWidth * _workingScale;
        Height = BaseHeight * _workingScale;
    }

    private void RestorePosition()
    {
        var cursor = Forms.Cursor.Position;
        var screen = ScreenGeometry.FromPoint(cursor);
        var area = screen.WorkingArea;
        var width = ScreenGeometry.WindowPixelWidth(this, screen);
        var height = ScreenGeometry.WindowPixelHeight(this, screen);
        var x = _state.Settings.CompanionLeft ?? area.Right - width - 28;
        var y = _state.Settings.CompanionTop ?? area.Bottom - height - 24;
        x = Math.Clamp(x, area.Left, Math.Max(area.Left, area.Right - width));
        y = Math.Clamp(y, area.Top, Math.Max(area.Top, area.Bottom - height));
        ScreenGeometry.SetPosition(this, x, y, screen);
    }

    private void ClampAndSavePosition()
    {
        var topLeft = PointToScreen(new System.Windows.Point(0, 0));
        var point = new Drawing.Point((int)topLeft.X, (int)topLeft.Y);
        var screen = ScreenGeometry.FromPoint(point);
        var area = screen.WorkingArea;
        var width = ScreenGeometry.WindowPixelWidth(this, screen);
        var height = ScreenGeometry.WindowPixelHeight(this, screen);
        var x = Math.Clamp(topLeft.X, area.Left, Math.Max(area.Left, area.Right - width));
        var y = Math.Clamp(topLeft.Y, area.Top, Math.Max(area.Top, area.Bottom - height));
        ScreenGeometry.SetPosition(this, x, y, screen);
        _state.Settings.CompanionLeft = x;
        _state.Settings.CompanionTop = y;
        _state.SaveAll();
    }
}
