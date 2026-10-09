import Foundation

public enum IslandMode: String, Codable, CaseIterable, Sendable {
    case idle
    case working
    case breakTime
    case alert
    case ai
    case water

    public var defaultTitle: String {
        switch self {
        case .idle: return "待命中"
        case .working: return "值班中"
        case .breakTime: return "休息倒计时"
        case .alert: return "提醒"
        case .ai: return "AI 任务完成"
        case .water: return "补给时间"
        }
    }
}

public enum ReminderKind: String, Codable, Sendable {
    case interval
    case fixedTime
}

// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
public struct IslandReminder: Identifiable, Codable, Equatable, Sendable {
    public var id: String
    public var title: String
    public var schedule: String
    public var enabled: Bool
    public var kind: ReminderKind

    public init(id: String, title: String, schedule: String, enabled: Bool, kind: ReminderKind) {
        self.id = id
        self.title = title
        self.schedule = schedule
        self.enabled = enabled
        self.kind = kind
    }

    public static let defaults = [
        IslandReminder(id: "move", title: "起身活动", schedule: "每 1 小时", enabled: true, kind: .interval),
        IslandReminder(id: "water", title: "喝水", schedule: "每 2 小时", enabled: true, kind: .interval),
        IslandReminder(id: "noon", title: "午间校准", schedule: "11:00", enabled: true, kind: .fixedTime),
        IslandReminder(id: "offwork", title: "下班", schedule: "16:30", enabled: true, kind: .fixedTime)
    ]
}

public struct IslandDailyRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: String { date }
    public var date: String
    public var workSeconds: Int
    public var breakSeconds: Int
    public var aiDoneCount: Int
    public var printableKeys: Int
    public var correctionKeys: Int
    public var activeTypingSeconds: Int
    public var actionCount: Int
    public var activeActionSeconds: Int
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).

    public init(
        date: String,
        workSeconds: Int = 0,
        breakSeconds: Int = 0,
        aiDoneCount: Int = 0,
        printableKeys: Int = 0,
        correctionKeys: Int = 0,
        activeTypingSeconds: Int = 0,
        actionCount: Int = 0,
        activeActionSeconds: Int = 0
    ) {
        self.date = date
        self.workSeconds = workSeconds
        self.breakSeconds = breakSeconds
        self.aiDoneCount = aiDoneCount
        self.printableKeys = printableKeys
        self.correctionKeys = correctionKeys
        self.activeTypingSeconds = activeTypingSeconds
        self.actionCount = actionCount
        self.activeActionSeconds = activeActionSeconds
    }

    public var effectiveKeys: Int {
        max(0, printableKeys - correctionKeys)
    }

    public var effectiveActionCount: Int {
        max(0, actionCount - correctionKeys)
    }

    public var hasActivity: Bool {
        workSeconds > 0
            || breakSeconds > 0
            || aiDoneCount > 0
            || printableKeys > 0
            || correctionKeys > 0
            || activeTypingSeconds > 0
            || actionCount > 0
            || activeActionSeconds > 0
    }
}

public struct IslandRecordBook: Codable, Equatable, Sendable {
    public var records: [String: IslandDailyRecord]

    public init(records: [String: IslandDailyRecord] = [:]) {
        self.records = records
    }

    public var activeDays: Int {
        records.values.filter(\.hasActivity).count
    }

    public var total: IslandDailyRecord {
        records.values.reduce(IslandDailyRecord(date: "total")) { partial, record in
            guard record.hasActivity else { return partial }
            return IslandDailyRecord(
                // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
                date: "total",
                workSeconds: partial.workSeconds + record.workSeconds,
                breakSeconds: partial.breakSeconds + record.breakSeconds,
                aiDoneCount: partial.aiDoneCount + record.aiDoneCount,
                printableKeys: partial.printableKeys + record.printableKeys,
                correctionKeys: partial.correctionKeys + record.correctionKeys,
                activeTypingSeconds: partial.activeTypingSeconds + record.activeTypingSeconds,
                actionCount: partial.actionCount + record.actionCount,
                activeActionSeconds: partial.activeActionSeconds + record.activeActionSeconds
            )
        }
    }

    public mutating func setToday(_ record: IslandDailyRecord) {
        records[record.date] = record
    }

    public mutating func clearToday(_ date: String) {
        records[date] = IslandDailyRecord(date: date)
    }

    public mutating func clearAll() {
        records.removeAll()
    }
}

public struct TypingStats: Codable, Equatable, Sendable {
    public var printableKeys: Int
    public var correctionKeys: Int
    public var activeTypingSeconds: Int
    public var actionCount: Int
    public var activeActionSeconds: Int

    public init(
        printableKeys: Int = 0,
        correctionKeys: Int = 0,
        activeTypingSeconds: Int = 0,
        actionCount: Int = 0,
        activeActionSeconds: Int = 0
    ) {
        self.printableKeys = printableKeys
        self.correctionKeys = correctionKeys
        self.activeTypingSeconds = activeTypingSeconds
        self.actionCount = actionCount
        self.activeActionSeconds = activeActionSeconds
    }

    public var effectiveKeys: Int {
        max(0, printableKeys - correctionKeys)
    }

    public var effectiveActionCount: Int {
        max(0, actionCount - correctionKeys)
    }

    public var correctionRate: Int {
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        guard printableKeys > 0 else { return 0 }
        return Int((Double(correctionKeys) / Double(printableKeys) * 100).rounded())
    }

    public var averageEffectiveSpeed: Int {
        guard activeTypingSeconds > 0 else { return 0 }
        return Int((Double(effectiveKeys) / Double(activeTypingSeconds) * 60).rounded())
    }

    @available(*, deprecated, message: "Use averageAPM(elapsedSeconds:) for the natural-time esports calculation.")
    public var averageAPM: Int {
        guard activeActionSeconds > 0 else { return 0 }
        return Int((Double(actionCount) / Double(activeActionSeconds) * 60).rounded())
    }

    public func averageAPM(elapsedSeconds: Int) -> Int {
        guard elapsedSeconds > 0 else { return 0 }
        return Int((Double(actionCount) / Double(elapsedSeconds) * 60).rounded())
    }

    public func averageEPM(elapsedSeconds: Int) -> Int {
        guard elapsedSeconds > 0 else { return 0 }
        return Int((Double(effectiveActionCount) / Double(elapsedSeconds) * 60).rounded())
    }
}

public enum IslandFormatting {
    public static func duration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    public static func dayKey(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

public enum IslandActivityPolicy {
    public static let automaticIdleThresholdSeconds = 30 * 60

    public static func mode(
        idleSeconds: Int,
        isOnBreak: Bool,
        thresholdSeconds: Int = automaticIdleThresholdSeconds
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    ) -> IslandMode {
        if isOnBreak {
            return .breakTime
        }
        return idleSeconds >= thresholdSeconds ? .idle : .working
    }
}
