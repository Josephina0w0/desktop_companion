import Cocoa

@MainActor
final class CompanionAppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private lazy var efficiency = EfficiencyIslandCoordinator()
    private lazy var tracker = TrackerCoordinator()
    private var statusItem: NSStatusItem?
    private let statusMenu = NSMenu()
    private var efficiencyPanelItem: NSMenuItem?
    private var pauseItem: NSMenuItem?
    private var endBreakItem: NSMenuItem?
    private var trackerPanelItem: NSMenuItem?

    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        setupStatusMenu()
        efficiency.start(statusButton: statusItem?.button)
        tracker.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication,
                                       hasVisibleWindows flag: Bool) -> Bool {
        tracker.handleReopen()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        efficiency.stop()
        tracker.stop()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        efficiencyPanelItem?.title = efficiency.isControlPanelVisible
            ? "隐藏效率岛控制面板" : "显示效率岛控制面板"
        pauseItem?.title = efficiency.isPaused ? "继续计时" : "暂停计时"
        endBreakItem?.isEnabled = efficiency.isOnBreak
        trackerPanelItem?.title = tracker.isPanelVisible ? "隐藏 Tracker" : "显示 Tracker"
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = item.button else { return }
        if let source = ImageResources.load(named: "statusIcon")?.copy() as? NSImage {
            let maxSide: CGFloat = 18
            let ratio = min(maxSide / max(source.size.width, 1),
                            maxSide / max(source.size.height, 1))
            source.size = NSSize(width: source.size.width * ratio,
                                 height: source.size.height * ratio)
            source.isTemplate = false
            button.image = source
            NSApp.applicationIconImage = source
        } else {
            button.title = "喻"
        }
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.toolTip = "Generic Companion"
        button.target = self
        button.action = #selector(showUnifiedMenu(_:))
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
    }

    private func setupStatusMenu() {
        statusMenu.autoenablesItems = false
        statusMenu.delegate = self

        let efficiencyRoot = NSMenuItem(title: "效率岛", action: nil, keyEquivalent: "")
        let efficiencyMenu = NSMenu(title: "效率岛")
        let panelItem = NSMenuItem(title: "显示效率岛控制面板",
                                   action: #selector(toggleEfficiencyPanel), keyEquivalent: "")
        panelItem.target = self
        efficiencyPanelItem = panelItem
        efficiencyMenu.addItem(panelItem)
        let breakItem = NSMenuItem(title: "休息 5 分钟", action: #selector(startBreak), keyEquivalent: "")
        breakItem.target = self
        efficiencyMenu.addItem(breakItem)
        let endItem = NSMenuItem(title: "结束休息", action: #selector(endBreak), keyEquivalent: "")
        endItem.target = self
        endBreakItem = endItem
        efficiencyMenu.addItem(endItem)
        let pause = NSMenuItem(title: "暂停计时", action: #selector(togglePause), keyEquivalent: "")
        pause.target = self
        pauseItem = pause
        efficiencyMenu.addItem(pause)
        efficiencyMenu.addItem(.separator())
        let efficiencyRecords = NSMenuItem(title: "打开效率岛记录",
                                           action: #selector(openEfficiencyRecords), keyEquivalent: "")
        efficiencyRecords.target = self
        efficiencyMenu.addItem(efficiencyRecords)
        efficiencyRoot.submenu = efficiencyMenu
        statusMenu.addItem(efficiencyRoot)

        let trackerRoot = NSMenuItem(title: "Tracker", action: nil, keyEquivalent: "")
        let trackerMenu = NSMenu(title: "Tracker")
        let trackerItem = NSMenuItem(title: "显示 Tracker",
                                    action: #selector(toggleTrackerPanel), keyEquivalent: "")
        trackerItem.target = self
        trackerPanelItem = trackerItem
        trackerMenu.addItem(trackerItem)
        let pipeline = NSMenuItem(title: "项目进度…",
                                  action: #selector(showApplications), keyEquivalent: "")
        pipeline.target = self
        trackerMenu.addItem(pipeline)
        let refresh = NSMenuItem(title: "刷新 iCloud 日历",
                                 action: #selector(refreshCalendar), keyEquivalent: "r")
        refresh.target = self
        trackerMenu.addItem(refresh)
        let settings = NSMenuItem(title: "Tracker 设置…",
                                  action: #selector(showTrackerSettings), keyEquivalent: ",")
        settings.target = self
        trackerMenu.addItem(settings)
        let trackerRecords = NSMenuItem(title: "打开 Tracker 记录",
                                        action: #selector(openTrackerRecords), keyEquivalent: "")
        trackerRecords.target = self
        trackerMenu.addItem(trackerRecords)
        trackerRoot.submenu = trackerMenu
        statusMenu.addItem(trackerRoot)

        statusMenu.addItem(.separator())
        let showBoth = NSMenuItem(title: "同时显示两个面板",
                                  action: #selector(showBothPanels), keyEquivalent: "")
        showBoth.target = self
        statusMenu.addItem(showBoth)
        let hideBoth = NSMenuItem(title: "隐藏两个面板",
                                  // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
                                  action: #selector(hideBothPanels), keyEquivalent: "")
        hideBoth.target = self
        statusMenu.addItem(hideBoth)
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        statusMenu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 Generic Companion",
                              action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        statusMenu.addItem(quit)
    }

    @objc private func showUnifiedMenu(_ sender: NSStatusBarButton) {
        statusMenu.popUp(positioning: nil,
                         at: NSPoint(x: 0, y: sender.bounds.height + 2),
                         in: sender)
    }

    @objc private func toggleEfficiencyPanel() { efficiency.toggleControlPanel() }
    @objc private func startBreak() { efficiency.startFiveMinuteBreak() }
    @objc private func endBreak() { efficiency.endCurrentBreak() }
    @objc private func togglePause() { efficiency.togglePause() }
    @objc private func openEfficiencyRecords() { efficiency.openRecordsFolder() }
    @objc private func toggleTrackerPanel() { tracker.togglePanel() }
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    @objc private func showApplications() { tracker.showApplications() }
    @objc private func refreshCalendar() { tracker.refreshCalendarData() }
    @objc private func showTrackerSettings() { tracker.showSettings() }
    @objc private func openTrackerRecords() { tracker.openRecordsFolder() }

    @objc private func showBothPanels() {
        efficiency.showControlPanel()
        tracker.showPanel()
    }

    @objc private func hideBothPanels() {
        efficiency.hideControlPanel()
        tracker.hidePanel()
    }

    @objc private func quitApp() { NSApp.terminate(nil) }
}

let app = NSApplication.shared
let companionDelegate = CompanionAppDelegate()
app.delegate = companionDelegate
app.run()
