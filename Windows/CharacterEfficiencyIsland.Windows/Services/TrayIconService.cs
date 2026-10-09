using CharacterEfficiencyIsland.Windows.Core;
using Drawing = System.Drawing;
using Forms = System.Windows.Forms;

namespace CharacterEfficiencyIsland.Windows.Services;

// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
internal sealed class TrayIconService : IDisposable
{
    private readonly Forms.NotifyIcon _notifyIcon;
    private readonly Drawing.Icon _icon;

    public TrayIconService(AppProfile profile, Action<Drawing.Point> togglePanel, Action quit)
    {
        _icon = AssetLoader.TrayIcon();
        _notifyIcon = new Forms.NotifyIcon
        {
            Icon = _icon,
            Text = profile.AppName.Length <= 63 ? profile.AppName : profile.AppName[..63],
            Visible = true
        };

        var menu = new Forms.ContextMenuStrip();
        menu.Items.Add("打开控制面板", null, (_, _) => togglePanel(Forms.Cursor.Position));
        menu.Items.Add(new Forms.ToolStripSeparator());
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        menu.Items.Add("退出", null, (_, _) => quit());
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        _notifyIcon.ContextMenuStrip = menu;
        _notifyIcon.MouseClick += (_, args) =>
        {
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            if (args.Button == Forms.MouseButtons.Left)
            {
                togglePanel(Forms.Cursor.Position);
            }
        };
        _notifyIcon.DoubleClick += (_, _) => togglePanel(Forms.Cursor.Position);
    }

    public void Notify(string title, string detail)
    {
        _notifyIcon.BalloonTipTitle = title;
        _notifyIcon.BalloonTipText = detail;
        _notifyIcon.ShowBalloonTip(3500);
    }
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).

    public void Dispose()
    {
        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
        _icon.Dispose();
    }
}
