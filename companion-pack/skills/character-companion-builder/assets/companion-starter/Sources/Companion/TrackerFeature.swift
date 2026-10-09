import Cocoa
@preconcurrency import EventKit

// MARK: - Persistent local state

enum PlanCategory: String, Codable, CaseIterable {
    case paper
    case external
    case internalWork = "internal"

    var label: String {
        switch self {
        case .paper: return "今日重点"
        case .external: return "沟通协作"
        case .internalWork: return "执行推进"
        }
    }
}

struct ImportedEvent: Codable {
    let id: String
    let date: String
    let type: String
    let category: PlanCategory
    let title: String
    let detail: String
    let nature: String
    let source: String

    var isImportantDate: Bool {
        if type == "deadline" { return true }
        let signal = "\(title) \(nature)".lowercased()
        let hardSignals = [
            "meeting", "interview", "appointment", "open call",
            "会议", "面谈", "预约", "发布", "交付", "截止", "复盘",
            "窗口首日", "窗口开始", "正式开始", "项目开始"
        ]
        return hardSignals.contains { signal.contains($0) }
    }

    var tooltip: String { "\(date) · \(nature) · \(detail) · 来源：\(source)" }
}

struct DailyTask: Codable {
    var text: String
    var isDone: Bool
    var importedEventID: String?
    var detail: String?

    init(text: String, isDone: Bool, importedEventID: String? = nil, detail: String? = nil) {
        self.text = text
        self.isDone = isDone
        self.importedEventID = importedEventID
        self.detail = detail
    }

    private enum CodingKeys: String, CodingKey { case text, isDone, importedEventID, detail }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decodeIfPresent(String.self, forKey: .text) ?? "点击这里编辑任务"
        isDone = try values.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        importedEventID = try values.decodeIfPresent(String.self, forKey: .importedEventID)
        detail = try values.decodeIfPresent(String.self, forKey: .detail)
    }
}

enum ApplicationStage: String, Codable, CaseIterable {
    case researching = "计划中"
    case outreachReady = "待开始"
    case contacted = "已开始"
    case discussing = "进行中"
    case materials = "准备交付"
    case submitted = "已提交"
    case interview = "审核／反馈"
    case offer = "已完成"
    case closed = "已归档"
}

struct ProjectItem: Codable {
    var id: String
    var priority: String
    var school: String
    var route: String
    var stage: ApplicationStage
    var supervisorContact: String
    var schoolContact: String
    var lastContactDate: String
    var nextFollowUpDate: String
    var deadline: String
    var nextAction: String

    static let defaults: [ProjectItem] = []
}

struct TrackerState: Codable {
    var trackerTitle = "日常 Tracker"
    var dailyTasks = [
        DailyTask(text: "今日重点：完成最重要的一件事", isDone: false),
        DailyTask(text: "沟通协作：处理一次必要沟通", isDone: false),
        DailyTask(text: "执行推进：推进一个项目下一步", isDone: false)
    ]
    var displayedMonth = Date().dayKey
    var selectedDate = Date().dayKey
    var panelVisible = true
    // nil means all current iCloud calendars; an explicit array is a saved filter.
    var selectedCalendarIDs: [String]? = nil
    var dailyTasksByDate: [String: [DailyTask]] = [:]
    var completedImportedIDs: [String] = []
    var projects = ProjectItem.defaults
    var thesisStatus = "进行中"
    var thesisNextAction = "写下当前最重要目标的下一步行动"

    init() {}

    private enum CodingKeys: String, CodingKey {
        case trackerTitle, dailyTasks, displayedMonth, selectedDate, panelVisible, selectedCalendarIDs
        case dailyTasksByDate, completedImportedIDs, projects, thesisStatus, thesisNextAction
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        trackerTitle = try values.decodeIfPresent(String.self, forKey: .trackerTitle) ?? "日常 Tracker"
        dailyTasks = try values.decodeIfPresent([DailyTask].self, forKey: .dailyTasks) ?? Self().dailyTasks
        displayedMonth = try values.decodeIfPresent(String.self, forKey: .displayedMonth) ?? Date().dayKey
        selectedDate = try values.decodeIfPresent(String.self, forKey: .selectedDate) ?? Date().dayKey
        panelVisible = try values.decodeIfPresent(Bool.self, forKey: .panelVisible) ?? true
        selectedCalendarIDs = try values.decodeIfPresent([String].self, forKey: .selectedCalendarIDs)
        dailyTasksByDate = try values.decodeIfPresent([String: [DailyTask]].self,
                                                      forKey: .dailyTasksByDate) ?? [:]
        completedImportedIDs = try values.decodeIfPresent([String].self,
                                                          forKey: .completedImportedIDs) ?? []
        projects = try values.decodeIfPresent([ProjectItem].self,
                                              forKey: .projects) ?? ProjectItem.defaults
        thesisStatus = try values.decodeIfPresent(String.self,
                                                  forKey: .thesisStatus) ?? "进行中"
        thesisNextAction = try values.decodeIfPresent(String.self,
                                                      forKey: .thesisNextAction)
            ?? "写下当前最重要目标的下一步行动"
    }
}

final class LocalStateStore {
    private(set) var state: TrackerState
    let supportDirectory: URL
    let stateURL: URL

    init() {
        supportDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/GenericCompanion/Tracker", isDirectory: true)
        stateURL = supportDirectory.appendingPathComponent("tracker-state.json")
        if let data = try? Data(contentsOf: stateURL),
           var decoded = try? JSONDecoder().decode(TrackerState.self, from: data) {
            while decoded.dailyTasks.count < 3 {
                decoded.dailyTasks.append(DailyTask(text: "点击这里编辑任务", isDone: false))
            }
            decoded.dailyTasks = Array(decoded.dailyTasks.prefix(3))
            state = decoded
        } else {
            state = TrackerState()
        }
    }

    func update(_ body: (inout TrackerState) -> Void) {
        body(&state)
        save()
    }

    func save() {
        try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: stateURL, options: .atomic)
    }

    func openFolder() {
        save()
        NSWorkspace.shared.open(supportDirectory)
    }
}

final class ImportedPlanStore {
    private let local: LocalStateStore
    private(set) var events: [ImportedEvent] = []

    init(local: LocalStateStore) {
        self.local = local
        if let url = trackerResourceURL(named: "calendar-events", extension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([ImportedEvent].self, from: data) {
            events = decoded.sorted(by: eventOrder)
        }
    }

    var totalCount: Int { events.count }
    var completedCount: Int {
        let completed = Set(local.state.completedImportedIDs)
        return events.filter { completed.contains($0.id) }.count
    }

    func events(on date: Date) -> [ImportedEvent] {
        events.filter { $0.date == date.dayKey }.sorted(by: eventOrder)
    }

    func importantEvents(on date: Date) -> [ImportedEvent] {
        events(on: date).filter(\.isImportantDate)
    }

    func upcomingImportant(from date: Date, limit: Int = 5) -> [ImportedEvent] {
        let completed = Set(local.state.completedImportedIDs)
        return Array(events
            .filter { $0.date >= date.dayKey && $0.isImportantDate && !completed.contains($0.id) }
            .sorted(by: eventOrder)
            .prefix(limit))
    }

    func recommendations(around date: Date, excluding excludedIDs: Set<String>,
                         limit: Int = 2) -> [ImportedEvent] {
        let calendar = Date.trackerCalendar
        let completed = Set(local.state.completedImportedIDs)
        let anchor = calendar.startOfDay(for: date)
        let futureEnd = calendar.date(byAdding: .day, value: 60, to: anchor) ?? anchor
        let recentStart = calendar.date(byAdding: .day, value: -21, to: anchor) ?? anchor
        let available: [(event: ImportedEvent, date: Date)] = events.compactMap { event in
            guard !excludedIDs.contains(event.id), !completed.contains(event.id),
                  let eventDate = Date.fromDayKey(event.date) else { return nil }
            return (event, calendar.startOfDay(for: eventDate))
        }

        var chosen = available
            .filter { $0.date >= anchor && $0.date <= futureEnd }
            .sorted(by: recommendationOrder)
            .map(\.event)
        if chosen.count < limit {
            let chosenIDs = Set(chosen.map(\.id))
            let recent = available
                .filter { $0.date < anchor && $0.date >= recentStart && !chosenIDs.contains($0.event.id) }
                .sorted { lhs, rhs in
                    if lhs.date != rhs.date { return lhs.date > rhs.date }
                    return eventOrder(lhs.event, rhs.event)
                }
                .map(\.event)
            chosen.append(contentsOf: recent)
        }
        if chosen.count < limit {
            let chosenIDs = Set(chosen.map(\.id))
            chosen.append(contentsOf: available
                .filter { $0.date > futureEnd && !chosenIDs.contains($0.event.id) }
                .sorted(by: recommendationOrder)
                .map(\.event))
        }
        return Array(chosen.prefix(limit))
    }

    func tasks(for date: Date) -> [DailyTask] {
        let key = date.dayKey
        if let saved = local.state.dailyTasksByDate[key], saved.count == 3 { return saved }
        let completed = Set(local.state.completedImportedIDs)
        let generated = PlanCategory.allCases.map { category -> DailyTask in
            if let event = candidate(for: category, date: date) {
                return DailyTask(
                    text: "\(category.label)：\(event.title)",
                    isDone: completed.contains(event.id),
                    importedEventID: event.id,
                    detail: event.tooltip)
            }
            let fallback: String
            switch category {
            case .paper: fallback = "今日重点：完成最重要的一件事"
            case .external: fallback = "沟通协作：处理一次必要沟通"
            case .internalWork: fallback = "执行推进：推进一个项目下一步"
            }
            return DailyTask(text: fallback, isDone: false,
                             detail: "当天没有未完成的对应导入事项，可直接点击改成今天的具体行动。")
        }
        local.update { $0.dailyTasksByDate[key] = generated }
        return generated
    }

    func updateTask(on date: Date, index: Int, text: String) {
        var tasks = tasks(for: date)
        guard tasks.indices.contains(index) else { return }
        tasks[index].text = text
        local.update { $0.dailyTasksByDate[date.dayKey] = tasks }
    }

    func toggleTask(on date: Date, index: Int, isDone: Bool) {
        var tasks = tasks(for: date)
        guard tasks.indices.contains(index) else { return }
        tasks[index].isDone = isDone
        let importedID = tasks[index].importedEventID
        local.update { state in
            state.dailyTasksByDate[date.dayKey] = tasks
            guard let importedID else { return }
            var completed = Set(state.completedImportedIDs)
            if isDone { completed.insert(importedID) } else { completed.remove(importedID) }
            state.completedImportedIDs = completed.sorted()
        }
    }

    func isCompleted(_ event: ImportedEvent) -> Bool {
        local.state.completedImportedIDs.contains(event.id)
    }

    private func candidate(for category: PlanCategory, date: Date) -> ImportedEvent? {
        let completed = Set(local.state.completedImportedIDs)
        let available = events.filter { $0.category == category && !completed.contains($0.id) }
        if let today = available.filter({ $0.date == date.dayKey }).sorted(by: eventOrder).first {
            return today
        }
        return available.filter { $0.date > date.dayKey }.sorted(by: eventOrder).first
    }

    private func recommendationOrder(_ lhs: (event: ImportedEvent, date: Date),
                                     _ rhs: (event: ImportedEvent, date: Date)) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        return eventOrder(lhs.event, rhs.event)
    }

    private func eventOrder(_ lhs: ImportedEvent, _ rhs: ImportedEvent) -> Bool {
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        if lhs.isImportantDate != rhs.isImportantDate { return lhs.isImportantDate }
        if lhs.type != rhs.type { return lhs.type == "deadline" }
        return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
    }
}

// MARK: - Date helpers

extension Date {
    static let trackerCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return calendar
    }()

    var dayKey: String {
        let values = Date.trackerCalendar.dateComponents([.year, .month, .day], from: self)
        return String(format: "%04d-%02d-%02d", values.year ?? 0, values.month ?? 0, values.day ?? 0)
    }

    static func fromDayKey(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = trackerCalendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}

private let monthFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Date.trackerCalendar
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy 年 M 月"
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "HH:mm"
    return formatter
}()

private func bundledImage(named name: String) -> NSImage? {
    guard let url = trackerResourceURL(named: name, extension: "png") else { return nil }
    return NSImage(contentsOf: url)
}

private func trackerResourceURL(named name: String, extension fileExtension: String) -> URL? {
    let filename = "\(name).\(fileExtension)"
    let resourceBundleName = "GenericCompanion_Companion.bundle"
    var candidates = [URL]()

    if let resourceURL = Bundle.main.resourceURL {
        candidates.append(
            resourceURL
                .appendingPathComponent("Tracker", isDirectory: true)
                .appendingPathComponent(filename)
        )
        candidates.append(
            resourceURL
                .appendingPathComponent(resourceBundleName, isDirectory: true)
                .appendingPathComponent("Tracker", isDirectory: true)
                .appendingPathComponent(filename)
        )
    }
    if let executableURL = Bundle.main.executableURL {
        candidates.append(
            executableURL
                .deletingLastPathComponent()
                .appendingPathComponent(resourceBundleName, isDirectory: true)
                .appendingPathComponent("Tracker", isDirectory: true)
                .appendingPathComponent(filename)
        )
    }
    return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
}

// MARK: - Read-only iCloud calendar

struct CalendarItem {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarName: String
    let location: String?

    var timeText: String { isAllDay ? "全天" : timeFormatter.string(from: startDate) }

    var tooltip: String {
        var parts = ["\(startDate.dayKey) \(timeText)", calendarName, title]
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        if let location, !location.isEmpty { parts.append(location) }
        return parts.joined(separator: " · ")
    }
}

struct CalendarChoice {
    let id: String
    let title: String
    let sourceTitle: String
}

@MainActor
final class ICloudCalendarReader: NSObject {
    private let eventStore = EKEventStore()

    var authorizationText: String {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized, .fullAccess: return "已授权只读显示"
        case .denied: return "日历访问已拒绝"
        case .restricted: return "日历访问受系统限制"
        case .writeOnly: return "仅写权限不可用于读取"
        case .notDetermined: return "尚未请求日历权限"
        @unknown default: return "日历权限状态未知"
        }
    }

    var canRead: Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14.0, *) { return status == .fullAccess }
        return status == .authorized
    }

    func requestAccess(completion: @escaping @MainActor (Bool) -> Void) {
        if canRead { completion(true); return }
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, _ in
                Task { @MainActor in completion(granted) }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, _ in
                Task { @MainActor in completion(granted) }
            }
        }
    }

    var availableCalendars: [CalendarChoice] {
        iCloudCalendars.map {
            CalendarChoice(id: $0.calendarIdentifier, title: $0.title, sourceTitle: $0.source.title)
        }.sorted { lhs, rhs in
            lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    func events(from start: Date, to end: Date, selectedIDs: [String]?) -> [CalendarItem] {
        guard canRead else { return [] }
        let calendars: [EKCalendar]
        if let selectedIDs {
            let allowed = Set(selectedIDs)
            calendars = iCloudCalendars.filter { allowed.contains($0.calendarIdentifier) }
        } else {
            calendars = iCloudCalendars
        }
        guard !calendars.isEmpty else { return [] }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return eventStore.events(matching: predicate).map {
            CalendarItem(id: $0.eventIdentifier ?? UUID().uuidString,
                         title: $0.title?.isEmpty == false ? $0.title! : "无标题事项",
                         startDate: $0.startDate,
                         endDate: $0.endDate,
                         isAllDay: $0.isAllDay,
                         calendarName: $0.calendar.title,
                         location: $0.location)
        }.sorted {
            if $0.startDate != $1.startDate { return $0.startDate < $1.startDate }
            return $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }

    func selectedCalendarCount(for selectedIDs: [String]?) -> Int {
        guard let selectedIDs else { return iCloudCalendars.count }
        let available = Set(iCloudCalendars.map(\.calendarIdentifier))
        return selectedIDs.filter { available.contains($0) }.count
    }

    private var iCloudCalendars: [EKCalendar] {
        eventStore.calendars(for: .event).filter {
            $0.source.title.localizedCaseInsensitiveContains("icloud")
        }
    }
}

// MARK: - Mouse-safe views

class FirstClickButton: NSButton {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class EditableTextField: NSTextField {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

final class PassthroughLabel: NSTextField {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    static func make(_ text: String, size: CGFloat, weight: NSFont.Weight,
                     color: NSColor = .labelColor) -> PassthroughLabel {
        let label = PassthroughLabel(labelWithString: text)
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        return label
    }
}

class PassthroughContainerView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        return result === self ? nil : result
    }
}

final class PassthroughVisualEffectView: NSVisualEffectView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class CharacterOverlayView: NSView {
    var image: NSImage?
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let image else { return }
        let target = NSRect(x: bounds.maxX - 117, y: 20, width: 104, height: 149)
        image.draw(in: target, from: .zero, operation: .sourceOver, fraction: 1,
                   respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    }
}

final class TrackerRootView: NSView {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeKey()
        window?.performDrag(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard point.y >= TrackerViewController.overflowHeight else { return nil }
        return super.hitTest(point)
    }
}

// MARK: - Calendar grid

final class CalendarDayButton: FirstClickButton {
    var date: Date?
    var selected = false
    var today = false
    var hasEvents = false

    override func draw(_ dirtyRect: NSRect) {
        guard !isHidden, let date else { return }
        if selected {
            NSColor.labelColor.withAlphaComponent(0.11).setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 1.5, dy: 1.5), xRadius: 7, yRadius: 7).fill()
        } else if today {
            NSColor.labelColor.withAlphaComponent(0.08).setFill()
            NSBezierPath(ovalIn: NSRect(x: bounds.midX - 9, y: 1, width: 18, height: 18)).fill()
        }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let day = Date.trackerCalendar.component(.day, from: date)
        let numberY: CGFloat = isFlipped ? 0.5 : 6
        ("\(day)" as NSString).draw(in: NSRect(x: 0, y: numberY, width: bounds.width, height: 15),
                                    withAttributes: [
                                        .font: NSFont.systemFont(ofSize: 12, weight: today ? .semibold : .medium),
                                        .foregroundColor: NSColor.labelColor,
                                        .paragraphStyle: paragraph
                                    ])
        if hasEvents {
            NSColor.labelColor.withAlphaComponent(0.62).setFill()
            let dotY: CGFloat = isFlipped ? bounds.height - 5 : 1.5
            NSBezierPath(ovalIn: NSRect(x: bounds.midX - 2, y: dotY, width: 4, height: 4)).fill()
        }
    }
}

final class MonthCalendarView: NSView {
    var month = Date() { didSet { updateButtons() } }
    var selectedDate = Date() { didSet { updateButtons() } }
    var itemsProvider: ((Date) -> [CalendarItem])? { didSet { updateButtons() } }
    var importedItemsProvider: ((Date) -> [ImportedEvent])? { didSet { updateButtons() } }
    var dateSelected: ((Date) -> Void)?
    private let headerHeight: CGFloat = 22
    private let weekdayNames = ["一", "二", "三", "四", "五", "六", "日"]
    private var buttons: [CalendarDayButton] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        for index in 0..<42 {
            let button = CalendarDayButton(frame: .zero)
            button.isBordered = false
            button.title = ""
            button.target = self
            button.action = #selector(selectDay(_:))
            button.identifier = NSUserInterfaceItemIdentifier("calendar-day-\(index)")
            button.focusRingType = .none
            button.isHidden = true
            addSubview(button)
            buttons.append(button)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func layout() { super.layout(); updateButtons() }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let width = bounds.width / 7
        for (index, name) in weekdayNames.enumerated() {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            (name as NSString).draw(in: NSRect(x: CGFloat(index) * width,
                                               y: bounds.height - headerHeight + 3,
                                               width: width, height: 15),
                                    withAttributes: [
                                        .font: NSFont.systemFont(ofSize: 10.5, weight: .semibold),
                                        .foregroundColor: NSColor.secondaryLabelColor,
                                        .paragraphStyle: paragraph
                                    ])
        }
    }

    func reload() { updateButtons() }

    @objc private func selectDay(_ sender: CalendarDayButton) {
        guard let date = sender.date else { return }
        window?.makeKey()
        dateSelected?(date)
    }

    private func updateButtons() {
        guard bounds.width > 0, bounds.height > headerHeight,
              let first = Date.trackerCalendar.date(from: Date.trackerCalendar.dateComponents([.year, .month], from: month)),
              let range = Date.trackerCalendar.range(of: .day, in: .month, for: first) else { return }
        let firstColumn = (Date.trackerCalendar.component(.weekday, from: first) + 5) % 7
        let cellWidth = bounds.width / 7
        let cellHeight = (bounds.height - headerHeight) / 6
        for button in buttons { button.isHidden = true; button.date = nil }

        for day in range {
            let index = firstColumn + day - 1
            guard index < buttons.count else { continue }
            let row = index / 7
            let column = index % 7
            let date = Date.trackerCalendar.date(byAdding: .day, value: day - 1, to: first) ?? first
            let items = itemsProvider?(date) ?? []
            let importedItems = importedItemsProvider?(date) ?? []
            let button = buttons[index]
            button.frame = NSRect(x: CGFloat(column) * cellWidth,
                                  y: bounds.height - headerHeight - CGFloat(row + 1) * cellHeight,
                                  width: cellWidth, height: cellHeight).insetBy(dx: 0.5, dy: 0.5)
            button.date = date
            button.selected = date.dayKey == selectedDate.dayKey
            button.today = date.dayKey == Date().dayKey
            button.hasEvents = !items.isEmpty || importedItems.contains(where: \.isImportantDate)
            let importedTitles = importedItems.filter(\.isImportantDate).map { "计划  \($0.title)" }
            button.toolTip = ([date.dayKey] + importedTitles
                + items.map { "日历  \($0.timeText)  \($0.title)" }).joined(separator: "\n")
            button.setAccessibilityElement(true)
            button.setAccessibilityLabel("\(date.dayKey) 日期")
            button.isHidden = false
            button.needsDisplay = true
        }
        needsDisplay = true
    }
}

// MARK: - Panel controls

final class SectionBox: PassthroughContainerView {
    let contentView = PassthroughContainerView()

    init(title: String, frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.cornerRadius = 13
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.labelColor.withAlphaComponent(0.14).cgColor
        let heading = PassthroughLabel.make(title, size: 12.5, weight: .bold)
        heading.frame = NSRect(x: 12, y: frame.height - 24, width: frame.width - 24, height: 17)
        addSubview(heading)
        contentView.frame = NSRect(x: 12, y: 9, width: frame.width - 24, height: frame.height - 38)
        addSubview(contentView)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.labelColor.withAlphaComponent(0.025).setFill()
        NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 13, yRadius: 13).fill()
    }
}

final class TrackerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class TrackerViewController: NSViewController, NSTextFieldDelegate {
    static let panelSize = NSSize(width: 420, height: 600)
    static let overflowHeight: CGFloat = 32
    static let windowSize = NSSize(width: 420, height: 632)

    private let local: LocalStateStore
    private let planStore: ImportedPlanStore
    private let calendarReader: ICloudCalendarReader
    private let resetPosition: () -> Void
    private let openSettings: () -> Void
    private let openApplications: () -> Void
    private var displayedMonth: Date
    private var selectedDate: Date
    private var calendarCache: [String: [CalendarItem]] = [:]

    private let titleField = EditableTextField(frame: .zero)
    private let monthLabel = PassthroughLabel.make("", size: 14, weight: .bold)
    private let calendarStatus = PassthroughLabel.make("", size: 9.5, weight: .medium,
                                                       color: .tertiaryLabelColor)
    private let calendarView = MonthCalendarView(frame: .zero)
    private let top3Box = SectionBox(title: "Daily Top 3", frame: NSRect(x: 220, y: 372, width: 176, height: 150))
    private let detailBox = SectionBox(title: "选中日期 · 日历与个人计划", frame: NSRect(x: 24, y: 276, width: 372, height: 68))
    private let upcomingBox = SectionBox(title: "近期关键日期", frame: NSRect(x: 24, y: 104, width: 372, height: 150))
    private var taskChecks: [FirstClickButton] = []
    private var taskFields: [EditableTextField] = []
    private var detailLabels: [PassthroughLabel] = []
    private var upcomingLabels: [PassthroughLabel] = []

    init(local: LocalStateStore, planStore: ImportedPlanStore,
         calendarReader: ICloudCalendarReader,
         resetPosition: @escaping () -> Void, openSettings: @escaping () -> Void,
         openApplications: @escaping () -> Void) {
        self.local = local
        self.planStore = planStore
        self.calendarReader = calendarReader
        self.resetPosition = resetPosition
        self.openSettings = openSettings
        self.openApplications = openApplications
        displayedMonth = Date.fromDayKey(local.state.displayedMonth) ?? Date()
        selectedDate = Date.fromDayKey(local.state.selectedDate) ?? Date()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let root = TrackerRootView(frame: NSRect(origin: .zero, size: Self.windowSize))
        root.wantsLayer = true
        view = root
        let blur = PassthroughVisualEffectView(frame: NSRect(x: 0, y: 48, width: 420, height: 568))
        blur.material = .popover
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 20
        blur.layer?.masksToBounds = true
        view.addSubview(blur)

        configureTitleField()
        view.addSubview(titleField)
        let subtitle = PassthroughLabel.make("角色 · 日程、任务与 iCloud 日历", size: 11.5, weight: .medium,
                                             color: .secondaryLabelColor)
        subtitle.frame = NSRect(x: 24, y: 561, width: 286, height: 16)
        view.addSubview(subtitle)
        let hint = PassthroughLabel.make("标题与任务可直接点击编辑", size: 9.5, weight: .medium,
                                         color: .tertiaryLabelColor)
        hint.alignment = .right
        hint.frame = NSRect(x: 260, y: 585, width: 136, height: 14)
        view.addSubview(hint)

        monthLabel.frame = NSRect(x: 24, y: 534, width: 142, height: 20)
        view.addSubview(monthLabel)
        let previous = makeButton("‹", #selector(previousMonth), "上个月")
        previous.frame = NSRect(x: 164, y: 531, width: 24, height: 24)
        view.addSubview(previous)
        let next = makeButton("›", #selector(nextMonth), "下个月")
        next.frame = NSRect(x: 190, y: 531, width: 24, height: 24)
        view.addSubview(next)

        calendarView.frame = NSRect(x: 24, y: 372, width: 172, height: 150)
        calendarView.itemsProvider = { [weak self] date in self?.calendarCache[date.dayKey] ?? [] }
        calendarView.importedItemsProvider = { [weak self] date in self?.planStore.events(on: date) ?? [] }
        calendarView.dateSelected = { [weak self] date in self?.selectDate(date) }
        view.addSubview(calendarView)
        calendarStatus.frame = NSRect(x: 24, y: 351, width: 190, height: 15)
        view.addSubview(calendarStatus)

        view.addSubview(top3Box)
        view.addSubview(detailBox)
        view.addSubview(upcomingBox)
        detailBox.contentView.frame = NSRect(x: 12, y: 5, width: detailBox.bounds.width - 24, height: 36)
        configureDailyTasks()
        configureCalendarLabels()

        let reset = makeButton("恢复默认位置", #selector(resetPanel), "恢复默认位置")
        reset.frame = NSRect(x: 24, y: 63, width: 100, height: 22)
        view.addSubview(reset)
        let records = makeButton("打开记录", #selector(openRecords), "打开记录")
        records.frame = NSRect(x: 132, y: 63, width: 82, height: 22)
        view.addSubview(records)
        let settings = makeButton("设置", #selector(showSettings), "设置")
        settings.frame = NSRect(x: 222, y: 63, width: 62, height: 22)
        view.addSubview(settings)
        let applications = makeButton("项目进度", #selector(showApplications), "打开项目进度")
        applications.frame = NSRect(x: 292, y: 63, width: 82, height: 22)
        view.addSubview(applications)
        let footer = PassthroughLabel.make("计划与完成状态仅自动保存在本机", size: 9.5, weight: .regular,
                                           color: .tertiaryLabelColor)
        footer.frame = NSRect(x: 24, y: 87, width: 270, height: 14)
        view.addSubview(footer)
        let art = CharacterOverlayView(frame: view.bounds)
        art.image = bundledImage(named: "character")
        art.autoresizingMask = [.width, .height]
        view.addSubview(art, positioned: .above, relativeTo: nil)
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        refreshAll()
        calendarReader.requestAccess { [weak self] _ in self?.reloadCalendar() }
    }

    func refreshAll() {
        titleField.stringValue = local.state.trackerTitle
        monthLabel.stringValue = monthFormatter.string(from: displayedMonth)
        calendarView.month = displayedMonth
        calendarView.selectedDate = selectedDate
        let tasks = planStore.tasks(for: Date())
        for index in 0..<3 {
            taskChecks[index].state = tasks[index].isDone ? .on : .off
            if taskFields[index].currentEditor() == nil {
                taskFields[index].stringValue = tasks[index].text
            }
            taskFields[index].toolTip = tasks[index].detail ?? "点击编辑；输入会自动保存"
        }
        reloadCalendar()
    }

    func reloadCalendar() {
        let availableCount = calendarReader.availableCalendars.count
        let selectedCount = calendarReader.selectedCalendarCount(for: local.state.selectedCalendarIDs)
        let planStatus = planStore.totalCount > 0
            ? "完成 \(planStore.completedCount)/\(planStore.totalCount)"
            : "本地计划"
        calendarStatus.stringValue = calendarReader.canRead
            ? "\(planStatus) · 日历 \(selectedCount)/\(availableCount)"
            : "\(planStatus) · \(calendarReader.authorizationText)"
        calendarCache.removeAll()
        guard let first = Date.trackerCalendar.date(from: Date.trackerCalendar.dateComponents([.year, .month], from: displayedMonth)),
              let start = Date.trackerCalendar.date(byAdding: .day, value: -7, to: first),
              let end = Date.trackerCalendar.date(byAdding: .day, value: 45, to: start) else {
            refreshCalendarText(); return
        }
        for item in calendarReader.events(from: start, to: end,
                                          selectedIDs: local.state.selectedCalendarIDs) {
            calendarCache[item.startDate.dayKey, default: []].append(item)
        }
        calendarView.reload()
        refreshCalendarText()
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        if field === titleField {
            local.update { $0.trackerTitle = field.stringValue.isEmpty ? "Tracker" : field.stringValue }
        } else if field.tag >= 100 && field.tag < 103 {
            let index = field.tag - 100
            planStore.updateTask(on: Date(), index: index, text: field.stringValue)
        }
    }

    private func configureTitleField() {
        titleField.frame = NSRect(x: 24, y: 580, width: 230, height: 25)
        titleField.stringValue = local.state.trackerTitle
        titleField.font = .systemFont(ofSize: 19, weight: .heavy)
        titleField.textColor = .labelColor
        titleField.isBordered = false
        titleField.drawsBackground = false
        titleField.focusRingType = .none
        titleField.delegate = self
        titleField.toolTip = "点击编辑 Tracker 标题；输入会自动保存"
        titleField.setAccessibilityLabel("可编辑 Tracker 标题")
    }

    private func configureDailyTasks() {
        let tasks = planStore.tasks(for: Date())
        for index in 0..<3 {
            let check = FirstClickButton(checkboxWithTitle: "", target: self, action: #selector(toggleTask(_:)))
            check.tag = index
            check.setButtonType(.switch)
            // Align the checkbox with the first baseline of the two-line task field.
            check.frame = NSRect(x: 0, y: top3Box.contentView.bounds.height - CGFloat(index + 1) * 37 + 17,
                                 width: 18, height: 18)
            check.setAccessibilityLabel("完成第 \(index + 1) 条任务")
            top3Box.contentView.addSubview(check)
            taskChecks.append(check)

            let field = EditableTextField(frame: NSRect(x: 21,
                y: top3Box.contentView.bounds.height - CGFloat(index + 1) * 37,
                width: top3Box.contentView.bounds.width - 21, height: 35))
            field.tag = 100 + index
            field.stringValue = tasks[index].text
            field.font = .systemFont(ofSize: 10, weight: .semibold)
            field.textColor = .labelColor
            field.isBordered = false
            field.drawsBackground = false
            field.focusRingType = .none
            field.lineBreakMode = .byWordWrapping
            field.maximumNumberOfLines = 2
            field.cell?.wraps = true
            field.cell?.usesSingleLineMode = false
            field.delegate = self
            field.placeholderString = "点击编辑任务"
            field.toolTip = tasks[index].detail ?? "点击编辑；输入会自动保存"
            field.setAccessibilityLabel("第 \(index + 1) 条可编辑任务")
            top3Box.contentView.addSubview(field)
            taskFields.append(field)
        }
    }

    private func configureCalendarLabels() {
        for index in 0..<2 {
            let label = PassthroughLabel.make("", size: 10, weight: .medium)
            label.frame = NSRect(x: 0, y: 18 - CGFloat(index) * 18,
                                 width: detailBox.contentView.bounds.width, height: 18)
            detailBox.contentView.addSubview(label)
            detailLabels.append(label)
        }
        for index in 0..<5 {
            let label = PassthroughLabel.make("", size: 10.5, weight: .medium)
            label.frame = NSRect(x: 0, y: upcomingBox.contentView.bounds.height - CGFloat(index + 1) * 21,
                                 width: index < 3 ? upcomingBox.contentView.bounds.width : 252,
                                 height: 18)
            upcomingBox.contentView.addSubview(label)
            upcomingLabels.append(label)
        }
    }

    private func refreshCalendarText() {
        let importedToday = planStore.events(on: selectedDate)
        let iCloudToday = calendarCache[selectedDate.dayKey] ?? []
        let recommendations = planStore.recommendations(
            around: selectedDate,
            excluding: Set(importedToday.map(\.id)),
            limit: max(0, 2 - importedToday.count - iCloudToday.count))
        var detailRows: [(text: String, tooltip: String)] = importedToday.map {
            ("计划 · \($0.title) · \($0.nature)", $0.tooltip)
        }
        detailRows.append(contentsOf: iCloudToday.map {
            ("日历 · \($0.timeText)  \($0.title)", $0.tooltip)
        })
        detailRows.append(contentsOf: recommendations.map {
            ("推荐 · \($0.title) · \($0.nature)",
             "临近推荐 · 原计划日 \($0.date) · \($0.tooltip)")
        })
        for (index, label) in detailLabels.enumerated() {
            if index < detailRows.count {
                let row = detailRows[index]
                label.isHidden = false
                label.stringValue = row.text
                label.toolTip = row.tooltip
            } else {
                label.isHidden = index > 0
                if index == 0 {
                    label.stringValue = "这一天没有日历事项或未完成计划"
                    label.toolTip = nil
                }
            }
        }

        let upcoming = planStore.upcomingImportant(from: Date(), limit: 5)
        for (index, label) in upcomingLabels.enumerated() {
            if index < upcoming.count {
                let item = upcoming[index]
                label.isHidden = false
                let shortDate = item.date.count >= 10 ? String(item.date.dropFirst(5)) : item.date
                label.stringValue = "\(shortDate)  \(item.title)"
                label.toolTip = item.tooltip
                label.font = .systemFont(ofSize: 10.5,
                                         weight: item.type == "deadline" ? .semibold : .medium)
            } else {
                label.isHidden = index > 0
                if index == 0 {
                    label.stringValue = "暂无未完成的近期关键日期"
                    label.toolTip = nil
                }
            }
        }
    }

    private func makeButton(_ title: String, _ action: Selector, _ accessibility: String) -> FirstClickButton {
        let button = FirstClickButton(title: title, target: self, action: action)
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        button.bezelStyle = .texturedRounded
        button.font = .systemFont(ofSize: 10.5, weight: .medium)
        button.setAccessibilityLabel(accessibility)
        return button
    }

    private func persistCalendarSelection() {
        local.update {
            $0.displayedMonth = displayedMonth.dayKey
            $0.selectedDate = selectedDate.dayKey
        }
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        calendarView.selectedDate = date
        persistCalendarSelection()
        refreshCalendarText()
    }

    @objc private func previousMonth() {
        displayedMonth = Date.trackerCalendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        monthLabel.stringValue = monthFormatter.string(from: displayedMonth)
        calendarView.month = displayedMonth
        persistCalendarSelection()
        reloadCalendar()
    }

    @objc private func nextMonth() {
        displayedMonth = Date.trackerCalendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        monthLabel.stringValue = monthFormatter.string(from: displayedMonth)
        calendarView.month = displayedMonth
        persistCalendarSelection()
        reloadCalendar()
    }

    @objc private func toggleTask(_ sender: NSButton) {
        let index = sender.tag
        guard index >= 0, index < 3 else { return }
        planStore.toggleTask(on: Date(), index: index, isDone: sender.state == .on)
        reloadCalendar()
    }

    @objc private func resetPanel() { resetPosition() }
    @objc private func openRecords() { local.openFolder() }
    @objc private func showSettings() { openSettings() }
    @objc private func showApplications() { openApplications() }
}

// MARK: - General project pipeline

@MainActor
final class ProjectPipelineViewController: NSViewController,
                                               NSTableViewDataSource,
                                               NSTableViewDelegate,
                                               NSTextFieldDelegate {
    private let local: LocalStateStore
    private let table = NSTableView(frame: .zero)
    private let thesisStatus = EditableTextField(frame: .zero)
    private let thesisNextAction = EditableTextField(frame: .zero)

    init(local: LocalStateStore) {
        self.local = local
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1040, height: 590))

        let title = PassthroughLabel.make("项目、任务与协作进度", size: 19, weight: .bold)
        title.frame = NSRect(x: 24, y: 548, width: 420, height: 25)
        view.addSubview(title)
        let subtitle = PassthroughLabel.make(
            "项目阶段、负责人、协作者、最近更新、下次跟进、截止日期和下一步都会自动保存。",
            size: 11, weight: .regular, color: .secondaryLabelColor)
        subtitle.frame = NSRect(x: 24, y: 526, width: 720, height: 18)
        view.addSubview(subtitle)

        let thesisBox = SectionBox(title: "当前重点目标", frame: NSRect(x: 24, y: 454, width: 992, height: 64))
        thesisStatus.frame = NSRect(x: 0, y: 2, width: 120, height: 22)
        thesisStatus.stringValue = local.state.thesisStatus
        thesisStatus.placeholderString = "目标状态"
        thesisStatus.delegate = self
        thesisStatus.tag = 9001
        thesisBox.contentView.addSubview(thesisStatus)
        thesisNextAction.frame = NSRect(x: 132, y: 2, width: 830, height: 22)
        thesisNextAction.stringValue = local.state.thesisNextAction
        thesisNextAction.placeholderString = "下一步"
        thesisNextAction.delegate = self
        thesisNextAction.tag = 9002
        thesisBox.contentView.addSubview(thesisNextAction)
        view.addSubview(thesisBox)

        let scroll = NSScrollView(frame: NSRect(x: 24, y: 58, width: 992, height: 384))
        scroll.borderType = .bezelBorder
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        table.usesAlternatingRowBackgroundColors = true
        table.rowHeight = 30
        table.headerView = NSTableHeaderView()
        table.delegate = self
        table.dataSource = self
        addColumn("priority", "优先", 52)
        addColumn("school", "项目／领域", 168)
        addColumn("route", "清单／子任务", 165)
        addColumn("stage", "阶段", 102)
        addColumn("supervisor", "负责人／协作者", 132)
        addColumn("schoolContact", "相关方／备注", 132)
        addColumn("lastContact", "最近更新", 88)
        addColumn("followUp", "下次跟进", 88)
        addColumn("deadline", "截止", 88)
        addColumn("nextAction", "下一步", 250)
        scroll.documentView = table
        view.addSubview(scroll)

        let add = FirstClickButton(title: "新增项目", target: self, action: #selector(addApplication))
        add.bezelStyle = .rounded
        add.frame = NSRect(x: 24, y: 18, width: 88, height: 28)
        view.addSubview(add)
        let remove = FirstClickButton(title: "删除所选", target: self, action: #selector(removeSelected))
        remove.bezelStyle = .rounded
        remove.frame = NSRect(x: 120, y: 18, width: 88, height: 28)
        view.addSubview(remove)
        let note = PassthroughLabel.make("日期可直接写 YYYY-MM-DD；阶段使用下拉菜单。", size: 10.5,
                                         weight: .regular, color: .secondaryLabelColor)
        note.frame = NSRect(x: 222, y: 24, width: 360, height: 16)
        view.addSubview(note)
    }

    private func addColumn(_ id: String, _ title: String, _ width: CGFloat) {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
        column.title = title
        column.width = width
        column.minWidth = min(48, width)
        table.addTableColumn(column)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        local.state.projects.count
    }

    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row >= 0, row < local.state.projects.count,
              let columnID = tableColumn?.identifier.rawValue else { return nil }
        let application = local.state.projects[row]

        if columnID == "stage" {
            let popup = NSPopUpButton(frame: .zero, pullsDown: false)
            popup.addItems(withTitles: ApplicationStage.allCases.map(\.rawValue))
            popup.selectItem(withTitle: application.stage.rawValue)
            popup.tag = row
            popup.target = self
            popup.action = #selector(stageChanged(_:))
            return popup
        }

        let values: [String: (Int, String)] = [
            "priority": (1, application.priority),
            "school": (2, application.school),
            "route": (3, application.route),
            "supervisor": (4, application.supervisorContact),
            "schoolContact": (5, application.schoolContact),
            "lastContact": (6, application.lastContactDate),
            "followUp": (7, application.nextFollowUpDate),
            "deadline": (8, application.deadline),
            "nextAction": (9, application.nextAction)
        ]
        guard let (fieldCode, value) = values[columnID] else { return nil }
        let field = EditableTextField(frame: .zero)
        field.stringValue = value
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 11)
        field.lineBreakMode = .byTruncatingTail
        field.delegate = self
        field.tag = row * 100 + fieldCode
        return field
    }

    func controlTextDidChange(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        if field.tag == 9001 {
            local.update { $0.thesisStatus = field.stringValue }
            return
        }
        if field.tag == 9002 {
            local.update { $0.thesisNextAction = field.stringValue }
            return
        }
        let row = field.tag / 100
        let code = field.tag % 100
        guard row >= 0, row < local.state.projects.count else { return }
        local.update { state in
            switch code {
            case 1: state.projects[row].priority = field.stringValue
            case 2: state.projects[row].school = field.stringValue
            case 3: state.projects[row].route = field.stringValue
            case 4: state.projects[row].supervisorContact = field.stringValue
            case 5: state.projects[row].schoolContact = field.stringValue
            case 6: state.projects[row].lastContactDate = field.stringValue
            case 7: state.projects[row].nextFollowUpDate = field.stringValue
            case 8: state.projects[row].deadline = field.stringValue
            case 9: state.projects[row].nextAction = field.stringValue
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            default: break
            }
        }
    }

    @objc private func stageChanged(_ sender: NSPopUpButton) {
        let row = sender.tag
        guard row >= 0, row < local.state.projects.count,
              let title = sender.selectedItem?.title,
              let stage = ApplicationStage(rawValue: title) else { return }
        local.update { $0.projects[row].stage = stage }
    }

    @objc private func addApplication() {
        let item = ProjectItem(
            id: UUID().uuidString, priority: "B", school: "新项目", route: "待拆解",
            stage: .researching, supervisorContact: "", schoolContact: "",
            lastContactDate: "", nextFollowUpDate: "", deadline: "待确认",
            nextAction: "明确目标、负责人、截止日期和下一步")
        local.update { $0.projects.append(item) }
        table.reloadData()
        table.scrollRowToVisible(max(0, local.state.projects.count - 1))
    }

    @objc private func removeSelected() {
        let row = table.selectedRow
        guard row >= 0, row < local.state.projects.count else { return }
        local.update { $0.projects.remove(at: row) }
        table.reloadData()
    }
}

// MARK: - Settings

@MainActor
final class SettingsViewController: NSViewController {
    private let local: LocalStateStore
    private let calendarReader: ICloudCalendarReader
    private let refreshCalendar: () -> Void
    private let close: () -> Void
    private let status = PassthroughLabel.make("", size: 11, weight: .medium,
                                               color: .secondaryLabelColor)
    private let calendarScroll = NSScrollView(frame: .zero)
    private let calendarList = NSView(frame: .zero)
    private var calendarChoices: [CalendarChoice] = []

    init(local: LocalStateStore, calendarReader: ICloudCalendarReader,
         refreshCalendar: @escaping () -> Void,
         close: @escaping () -> Void) {
        self.local = local
        self.calendarReader = calendarReader
        self.refreshCalendar = refreshCalendar
        self.close = close
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 410, height: 420))
        let title = PassthroughLabel.make("Tracker 设置", size: 18, weight: .bold)
        title.frame = NSRect(x: 24, y: 377, width: 250, height: 24)
        view.addSubview(title)
        let calendarTitle = PassthroughLabel.make("显示这些 iCloud 日历（只读）", size: 12, weight: .semibold)
        calendarTitle.frame = NSRect(x: 24, y: 344, width: 220, height: 18)
        view.addSubview(calendarTitle)
        status.frame = NSRect(x: 238, y: 344, width: 148, height: 18)
        status.alignment = .right
        view.addSubview(status)

        calendarScroll.frame = NSRect(x: 24, y: 151, width: 362, height: 184)
        calendarScroll.borderType = .bezelBorder
        calendarScroll.hasVerticalScroller = true
        calendarScroll.autohidesScrollers = true
        calendarScroll.drawsBackground = false
        calendarScroll.documentView = calendarList
        view.addSubview(calendarScroll)

        let selectAll = FirstClickButton(title: "全选", target: self, action: #selector(selectAllCalendars))
        selectAll.bezelStyle = .rounded
        selectAll.frame = NSRect(x: 24, y: 113, width: 66, height: 28)
        view.addSubview(selectAll)
        let selectNone = FirstClickButton(title: "全不选", target: self, action: #selector(selectNoCalendars))
        selectNone.bezelStyle = .rounded
        selectNone.frame = NSRect(x: 96, y: 113, width: 72, height: 28)
        view.addSubview(selectNone)
        let permission = FirstClickButton(title: "授权／刷新日历", target: self, action: #selector(requestCalendar))
        permission.bezelStyle = .rounded
        permission.frame = NSRect(x: 256, y: 113, width: 130, height: 28)
        view.addSubview(permission)
        let privacy = NSTextField(wrappingLabelWithString:
            "Tracker 只读取所选 iCloud 日历，不会创建、修改或删除事项。日历选择、自定义标题、Daily Top 3、勾选状态、月份与选中日期仅保存在本机。")
        privacy.font = .systemFont(ofSize: 11)
        privacy.textColor = .secondaryLabelColor
        privacy.frame = NSRect(x: 24, y: 52, width: 362, height: 48)
        view.addSubview(privacy)
        let done = FirstClickButton(title: "完成", target: self, action: #selector(done))
        done.bezelStyle = .rounded
        done.keyEquivalent = "\r"
        done.frame = NSRect(x: 308, y: 16, width: 78, height: 28)
        view.addSubview(done)
        rebuildCalendarList()
    }

    func updateStatus() {
        guard calendarReader.canRead else {
            status.stringValue = calendarReader.authorizationText
            return
        }
        let selected = calendarReader.selectedCalendarCount(for: local.state.selectedCalendarIDs)
        status.stringValue = "已选 \(selected)/\(calendarReader.availableCalendars.count)"
    }

    func rebuildCalendarList() {
        calendarChoices = calendarReader.availableCalendars
        calendarList.subviews.forEach { $0.removeFromSuperview() }
        let visibleHeight = calendarScroll.contentSize.height
        let documentHeight = max(visibleHeight, CGFloat(calendarChoices.count) * 28 + 10)
        calendarList.frame = NSRect(x: 0, y: 0,
                                    width: max(calendarScroll.contentSize.width, 340),
                                    height: documentHeight)

        if calendarChoices.isEmpty {
            let message = PassthroughLabel.make(
                calendarReader.canRead ? "没有找到 iCloud 日历" : "授权后可选择要显示的日历",
                size: 11, weight: .regular, color: .secondaryLabelColor)
            message.alignment = .center
            message.frame = NSRect(x: 12, y: documentHeight / 2 - 9,
                                   width: calendarList.bounds.width - 24, height: 18)
            calendarList.addSubview(message)
        } else {
            let selected = local.state.selectedCalendarIDs.map(Set.init)
            for (index, choice) in calendarChoices.enumerated() {
                let check = FirstClickButton(checkboxWithTitle: choice.title,
                                             target: self, action: #selector(toggleCalendar(_:)))
                check.tag = index
                check.state = selected == nil || selected!.contains(choice.id) ? .on : .off
                check.font = .systemFont(ofSize: 11.5, weight: .regular)
                check.lineBreakMode = .byTruncatingTail
                check.toolTip = "\(choice.title) · \(choice.sourceTitle)"
                check.frame = NSRect(x: 10,
                                     y: documentHeight - CGFloat(index + 1) * 28,
                                     width: calendarList.bounds.width - 20, height: 22)
                check.setAccessibilityLabel("显示日历 \(choice.title)")
                calendarList.addSubview(check)
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            }
        }
        calendarScroll.documentView = calendarList
        updateStatus()
    }

    @objc private func requestCalendar() {
        calendarReader.requestAccess { [weak self] _ in
            self?.rebuildCalendarList()
            self?.refreshCalendar()
        }
    }

    @objc private func toggleCalendar(_ sender: NSButton) {
        guard sender.tag >= 0, sender.tag < calendarChoices.count else { return }
        var selected = Set(local.state.selectedCalendarIDs ?? calendarChoices.map(\.id))
        let identifier = calendarChoices[sender.tag].id
        if sender.state == .on { selected.insert(identifier) } else { selected.remove(identifier) }
        local.update { $0.selectedCalendarIDs = Array(selected).sorted() }
        updateStatus()
        refreshCalendar()
    }

    @objc private func selectAllCalendars() {
        local.update { $0.selectedCalendarIDs = nil }
        rebuildCalendarList()
        refreshCalendar()
    }

    @objc private func selectNoCalendars() {
        local.update { $0.selectedCalendarIDs = [] }
        rebuildCalendarList()
        refreshCalendar()
    }

    @objc private func done() { close() }
}

// MARK: - Application

private enum Preferences {
    static let frameName = "GenericCompanionTrackerPanel"
    static let originX = "generalCompanionTrackerPanelOriginX"
    static let originY = "generalCompanionTrackerPanelOriginY"
}

@MainActor
final class TrackerCoordinator: NSObject, NSWindowDelegate {
    private let local = LocalStateStore()
    private lazy var planStore = ImportedPlanStore(local: local)
    private let calendarReader = ICloudCalendarReader()
    private var panel: TrackerPanel?
    private var controller: TrackerViewController?
    private var settingsWindow: NSWindow?
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    private var settingsController: SettingsViewController?
    private var applicationsWindow: NSWindow?
    private var applicationsController: ProjectPipelineViewController?
    private var refreshTimer: Timer?

    func start() {
        setupPanel()
        restorePosition()
        if ProcessInfo.processInfo.environment["GENERIC_COMPANION_PREVIEW_MODE"] == nil,
           local.state.panelVisible {
            showPanel()
        }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshCalendarData() }
        }
    }

    func handleReopen() {
        showPanel()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        local.update { $0.panelVisible = panel?.isVisible == true }
        settingsWindow?.close()
        applicationsWindow?.close()
        panel?.orderOut(nil)
        panel?.close()
    }

    func windowDidMove(_ notification: Notification) {
        guard let panel, notification.object as? NSWindow === panel else { return }
        savePosition()
    }

    private func setupPanel() {
        let panel = TrackerPanel(contentRect: NSRect(origin: .zero, size: TrackerViewController.windowSize),
                                 styleMask: [.borderless], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.hidesOnDeactivate = false
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.setContentSize(TrackerViewController.windowSize)
        panel.minSize = TrackerViewController.windowSize
        panel.maxSize = TrackerViewController.windowSize
        panel.setFrameAutosaveName(Preferences.frameName)
        panel.title = "Tracker"
        panel.delegate = self
        let controller = TrackerViewController(
            local: local, planStore: planStore, calendarReader: calendarReader,
            resetPosition: { [weak self] in self?.positionAtDefault() },
            openSettings: { [weak self] in self?.showSettings() },
            openApplications: { [weak self] in self?.showApplications() })
        panel.contentViewController = controller
        self.panel = panel
        self.controller = controller
    }

    func showSettings() {
        if let settingsWindow {
            settingsController?.rebuildCalendarList()
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = SettingsViewController(
            local: local,
            calendarReader: calendarReader,
            refreshCalendar: { [weak self] in self?.controller?.reloadCalendar() },
            close: { [weak self] in self?.settingsWindow?.close() })
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 410, height: 420),
                              styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Tracker 设置"
        window.contentViewController = controller
        window.center()
        window.isReleasedWhenClosed = false
        settingsController = controller
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showApplications() {
        if let applicationsWindow {
            applicationsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let controller = ProjectPipelineViewController(local: local)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 590),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "项目进度"
        window.contentViewController = controller
        window.minSize = NSSize(width: 820, height: 460)
        window.center()
        window.isReleasedWhenClosed = false
        applicationsController = controller
        applicationsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showPanel() {
        guard let panel else { return }
        panel.ignoresMouseEvents = false
        panel.makeKeyAndOrderFront(nil)
        local.update { $0.panelVisible = true }
        controller?.refreshAll()
    }

    func hidePanel() {
        panel?.orderOut(nil)
        local.update { $0.panelVisible = false }
    }

    var isPanelVisible: Bool { panel?.isVisible == true }

    func togglePanel() {
        isPanelVisible ? hidePanel() : showPanel()
    }

    private func positionAtDefault() {
        guard let panel, let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(x: frame.minX + 24,
                                     y: frame.maxY - TrackerViewController.windowSize.height - 24))
        savePosition()
    }

    private func restorePosition() {
        guard let panel else { return }
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Preferences.originX) != nil,
           defaults.object(forKey: Preferences.originY) != nil {
            panel.setFrameOrigin(NSPoint(x: defaults.double(forKey: Preferences.originX),
                                         y: defaults.double(forKey: Preferences.originY)))
        } else if !panel.setFrameUsingName(Preferences.frameName) {
            positionAtDefault()
        }
    }

    private func savePosition() {
        guard let panel else { return }
        panel.saveFrame(usingName: Preferences.frameName)
        UserDefaults.standard.set(panel.frame.origin.x, forKey: Preferences.originX)
        UserDefaults.standard.set(panel.frame.origin.y, forKey: Preferences.originY)
    }

    func resetPositionAndShow() { positionAtDefault(); showPanel() }
    func openRecordsFolder() { local.openFolder() }
    func refreshCalendarData() {
        controller?.reloadCalendar()
        settingsController?.rebuildCalendarList()
    }
}
