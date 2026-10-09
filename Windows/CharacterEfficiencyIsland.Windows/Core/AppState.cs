using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Text.RegularExpressions;

namespace CharacterEfficiencyIsland.Windows.Core;

public sealed class AppState
{
    private readonly LocalStore _store;
    private readonly Queue<(DateTimeOffset Time, bool Correction)> _typingWindow = new();
    private readonly Queue<DateTimeOffset> _activeTypingSecondMarks = new();
    private readonly Queue<(DateTimeOffset Time, bool Effective)> _actionWindow = new();
    private readonly HashSet<string> _reminderKeys = new();
    private Dictionary<string, DailyRecord> _records;
    private string _dayKey;
    private DateTimeOffset? _lastTypingAt;
    private int _saveTick;
    private CharacterMode? _visualMode;
    private DateTimeOffset? _visualModeExpiresAt;
    private string? _visualDetail;

    internal AppState(AppProfile profile, LocalStore store)
    {
        Profile = profile;
        _store = store;
        Settings = store.LoadSettings(profile);
        _records = store.LoadRecords();
        _dayKey = DayKey(DateTimeOffset.Now);
        ApplyRecord(_records.GetValueOrDefault(_dayKey));
    }

    public AppProfile Profile { get; }
    public AppSettings Settings { get; }
    public CharacterMode Mode { get; private set; } = CharacterMode.Working;
    public CharacterMode DisplayMode =>
        _visualModeExpiresAt is { } expiry && DateTimeOffset.Now < expiry && _visualMode is { } visual
            ? visual
            : Mode;
    public string DisplayTitle => Profile.Title(DisplayMode);
    public string DisplayDetail
    {
        get
        {
            if (_visualModeExpiresAt is { } expiry && DateTimeOffset.Now < expiry &&
                !string.IsNullOrWhiteSpace(_visualDetail))
            {
                return _visualDetail;
            }
            return Mode switch
            {
                CharacterMode.BreakTime when IsBreakTimerPaused => "倒计时暂停。准备好后再继续。",
                CharacterMode.BreakTime => "不用着急",
                CharacterMode.Idle => Profile.Detail(CharacterMode.Idle),
                _ => $"稳步推进 {FormatSeconds(WorkSeconds)} · EPM {(_actionWindow.Count == 0 ? "--" : CurrentEpm.ToString("00"))}"
            };
        }
    }
    public bool IsPaused { get; private set; }
    public bool IsOnBreak { get; private set; }
    public bool IsBreakTimerPaused { get; private set; }
    public int BreakRemaining { get; private set; }
    public int WorkSeconds { get; private set; }
    public int BreakSeconds { get; private set; }
    public int AiDoneCount { get; private set; }
    public int WaterCheckins { get; private set; }
    public int TotalPrintableKeys { get; private set; }
    public int TotalCorrectionKeys { get; private set; }
    public int ActiveTypingSeconds { get; private set; }
    public int TotalActions { get; private set; }
    public int TotalEffectiveActions { get; private set; }
    public string InputStatus { get; set; } = "输入监测准备中";
    public string CodexStatus { get; set; } = "Codex 检测准备中";

    public event EventHandler? Changed;
    public event EventHandler<string>? NotificationRaised;

    public IReadOnlyList<SoftReminder> Reminders => Settings.Reminders;
    public int CurrentApm => _actionWindow.Count;
    public int CurrentEpm => _actionWindow.Count(item => item.Effective);
    public int CurrentRawSpeed
    {
        get
        {
            var activeSeconds = Math.Max(1, _activeTypingSecondMarks.Count);
            var printable = _typingWindow.Count(item => !item.Correction);
            return (int)Math.Round(printable / (double)activeSeconds * 60);
        }
    }
    public int CorrectionRate => TotalPrintableKeys == 0
        ? 0
        : (int)Math.Round(TotalCorrectionKeys / (double)TotalPrintableKeys * 100);
    public int AverageEffectiveSpeed => ActiveTypingSeconds == 0
        ? 0
        : (int)Math.Round(Math.Max(0, TotalPrintableKeys - TotalCorrectionKeys) /
            (double)ActiveTypingSeconds * 60);
    public int AverageApm => WorkSeconds == 0
        ? 0
        : (int)Math.Round(TotalActions / (double)WorkSeconds * 60);
    public int AverageEpm => WorkSeconds == 0
        ? 0
        : (int)Math.Round(TotalEffectiveActions / (double)WorkSeconds * 60);

    public DailyRecord TodayRecord => SnapshotRecord(_dayKey);
    public DailyRecord TotalRecord => RecordsSnapshot().Values
        .Where(record => record.HasActivity)
        .Aggregate(new DailyRecord { Date = "total" }, AddRecords);
    public int ActiveRecordDays => RecordsSnapshot().Values.Count(record => record.HasActivity);

    public void Tick(TimeSpan idleTime)
    {
        var now = DateTimeOffset.Now;
        RolloverIfNeeded(now);
        PruneWindows(now);
        ClearExpiredVisual(now);

        if (!IsPaused)
        {
            if (IsOnBreak)
            {
                Mode = CharacterMode.BreakTime;
                if (!IsBreakTimerPaused)
                {
                    BreakSeconds++;
                    BreakRemaining = Math.Max(0, BreakRemaining - 1);
                }
                if (BreakRemaining == 0)
                {
                    FinishBreak();
                }
            }
            else
            {
                Mode = idleTime >= TimeSpan.FromMinutes(30)
                    ? CharacterMode.Idle
                    : CharacterMode.Working;
                if (Mode == CharacterMode.Working)
                {
                    WorkSeconds++;
                }
                if (idleTime > TimeSpan.FromMinutes(15) && idleTime < TimeSpan.FromMinutes(30))
                {
                    RaiseOnce(
                        $"idle-{now:yyyyMMddHHmm}",
                        CharacterMode.Alert,
                        "已经空闲 15 分钟。如果是在休息，记得开启休息计时。",
                        TimeSpan.FromSeconds(7));
                }
            }

            if (_lastTypingAt is { } last && now - last <= TimeSpan.FromSeconds(5))
            {
                ActiveTypingSeconds++;
                _activeTypingSecondMarks.Enqueue(now);
            }

            CheckReminderSchedule(now);
        }

        _saveTick++;
        if (_saveTick >= 10)
        {
            _saveTick = 0;
            SaveRecords();
        }
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void RecordInput(InputAction input)
    {
        if (input.IsRepeat)
        {
            return;
        }

        var now = DateTimeOffset.Now;
        TotalActions++;
        var effective = !input.IsCorrection;
        if (effective)
        {
            TotalEffectiveActions++;
        }
        _actionWindow.Enqueue((now, effective));

        if (input.IsKeyboard)
        {
            if (input.IsCorrection)
            {
                TotalCorrectionKeys++;
                _typingWindow.Enqueue((now, true));
                _lastTypingAt = now;
            }
            else if (input.IsPrintable)
            {
                TotalPrintableKeys++;
                _typingWindow.Enqueue((now, false));
                _lastTypingAt = now;
            }
        }

        PruneWindows(now);
        Changed?.Invoke(this, EventArgs.Empty);
    }

    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    public void StartBreak(int seconds = 300)
    {
        IsOnBreak = true;
        IsBreakTimerPaused = false;
        BreakRemaining = Math.Max(1, seconds);
        Mode = CharacterMode.BreakTime;
        ShowTemporary(CharacterMode.BreakTime, "休息开始。先放松一下。", TimeSpan.FromSeconds(4));
    }

    public void EndBreak()
    {
        if (!IsOnBreak)
        {
            ShowTemporary(CharacterMode.Alert, "当前没有进行中的休息。", TimeSpan.FromSeconds(4));
            return;
        }
        FinishBreak("休息已结束。按当前节奏继续。", false);
    }

    public void ToggleBreakPause()
    {
        if (!IsOnBreak)
        {
            return;
        }
        IsBreakTimerPaused = !IsBreakTimerPaused;
        NotificationRaised?.Invoke(this, IsBreakTimerPaused ? "休息倒计时已暂停。" : "休息倒计时已继续。");
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void TogglePause()
    {
        IsPaused = !IsPaused;
        NotificationRaised?.Invoke(this, IsPaused ? "统计与计时已暂停。" : "统计与计时已继续。");
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void CheckInWater()
    {
        WaterCheckins++;
        ShowTemporary(CharacterMode.Water, $"喝水打卡 +1。今天第 {WaterCheckins} 次。", TimeSpan.FromSeconds(7));
        SaveRecords();
    }

    public void RecordCodexCompletion(int count)
    {
        if (count <= 0)
        {
            return;
        }
        AiDoneCount += count;
        ShowTemporary(CharacterMode.Ai, $"Codex 新完成 {count} 个回合。先验收结果，再继续。", TimeSpan.FromSeconds(8));
        SaveRecords();
    }

    public void ShowTemporary(CharacterMode mode, string detail, TimeSpan duration)
    {
        _visualMode = mode;
        _visualModeExpiresAt = DateTimeOffset.Now + duration;
        _visualDetail = detail;
        NotificationRaised?.Invoke(this, detail);
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void UpdateReminder(string id, bool enabled, string title, string schedule)
    {
        var reminder = Settings.Reminders.FirstOrDefault(item => item.Id == id);
        if (reminder is null)
        {
            return;
        }
        reminder.Enabled = enabled;
        if (!id.Equals("water", StringComparison.OrdinalIgnoreCase) && !string.IsNullOrWhiteSpace(title))
        {
            reminder.Title = title.Trim();
        }
        if (!string.IsNullOrWhiteSpace(schedule))
        {
            reminder.Schedule = schedule.Trim();
        }
        SaveSettings();
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void SetSurfaceVisible(bool value)
    {
        Settings.ShowPersistentSurface = value;
        SaveSettings();
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void SetAiRemindersEnabled(bool value)
    {
        Settings.AiRemindersEnabled = value;
        SaveSettings();
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void SetSurfaceScale(double value)
    {
        Settings.SurfaceScale = Math.Clamp(value, 0.75, 1.60);
        SaveSettings();
        Changed?.Invoke(this, EventArgs.Empty);
    }

    public void SetPanelScale(double value, bool companion)
    {
        if (companion)
        {
            Settings.CompanionPanelScale = Math.Clamp(value, 0.65, 1.60);
        }
        else
        {
            Settings.DynamicIslandPanelScale = Math.Clamp(value, 0.65, 1.60);
        }
        SaveSettings();
    }

    public void ResetToday()
    {
        _records[_dayKey] = new DailyRecord { Date = _dayKey };
        ResetCounters();
        SaveRecords();
        ShowTemporary(CharacterMode.Alert, "今日记录已清零。", TimeSpan.FromSeconds(4));
    }

    public void ResetAll()
    {
        _records.Clear();
        ResetCounters();
        SaveRecords();
        ShowTemporary(CharacterMode.Alert, "全部记录已清空。", TimeSpan.FromSeconds(4));
    }

    public void SaveAll()
    {
        SaveSettings();
        SaveRecords();
    }

    public void OpenRecordFolder()
    {
        SaveRecords();
        Directory.CreateDirectory(_store.Folder);
        Process.Start(new ProcessStartInfo
        {
            FileName = _store.Folder,
            UseShellExecute = true
        });
    }

    public string FormatSeconds(int seconds)
    {
        var duration = TimeSpan.FromSeconds(Math.Max(0, seconds));
        return duration.TotalHours >= 1
            ? $"{(int)duration.TotalHours}:{duration.Minutes:00}:{duration.Seconds:00}"
            : $"{duration.Minutes:00}:{duration.Seconds:00}";
    }

    private void FinishBreak(string detail = "五分钟到了。回来吧，可以看看下一步了。", bool natural = true)
    {
        IsOnBreak = false;
        IsBreakTimerPaused = false;
        BreakRemaining = 0;
        Mode = CharacterMode.Working;
        ShowTemporary(CharacterMode.Alert, detail, TimeSpan.FromSeconds(natural ? 8 : 5));
    }

    private void CheckReminderSchedule(DateTimeOffset now)
    {
        var elapsedMinutes = WorkSeconds / 60;
        for (var index = 0; index < Settings.Reminders.Count; index++)
        {
            var reminder = Settings.Reminders[index];
            if (!reminder.Enabled)
            {
                continue;
            }

            if (TimeOnly.TryParseExact(reminder.Schedule.Trim(), "H:mm", CultureInfo.InvariantCulture,
                    DateTimeStyles.None, out var target) ||
                TimeOnly.TryParseExact(reminder.Schedule.Trim(), "HH:mm", CultureInfo.InvariantCulture,
                    DateTimeStyles.None, out target))
            {
                if (now.Hour == target.Hour && now.Minute == target.Minute)
                {
                    RaiseReminder(reminder, index, $"{reminder.Id}-{now:yyyyMMdd}");
                }
                continue;
            }

            var interval = IntervalMinutes(reminder.Schedule);
            if (interval > 0 && elapsedMinutes > 0 && elapsedMinutes % interval == 0)
            {
                RaiseReminder(reminder, index, $"{reminder.Id}-{elapsedMinutes / interval}");
            }
        }
    }

    private void RaiseReminder(SoftReminder reminder, int index, string key)
    {
        if (!_reminderKeys.Add(key))
        {
            return;
        }
        var mode = index switch
        {
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            0 => CharacterMode.ReminderFirst,
            1 => CharacterMode.ReminderSecond,
            2 => CharacterMode.ReminderThird,
            3 => CharacterMode.ReminderFourth,
            _ => CharacterMode.Alert
        };
        var detail = reminder.Id switch
        {
            "water" => "喝口水。状态稳定，后面的安排才不会乱。",
            "move" => "起来走一走。调整一下，回来会更专注。",
            "noon" => "看一下当前进度。保留有效的，调整不合适的。",
            "offwork" => "今天先收好尾。清楚地结束，明天才容易开始。",
            _ => "提醒时间到了。"
        };
        ShowTemporary(mode, detail, TimeSpan.FromSeconds(7));
    }

    private void RaiseOnce(string key, CharacterMode mode, string detail, TimeSpan duration)
    {
        if (_reminderKeys.Add(key))
        {
            ShowTemporary(mode, detail, duration);
        }
    }

    private static int IntervalMinutes(string value)
    {
        var match = Regex.Match(value, @"\d+(?:\.\d+)?");
        if (!match.Success || !double.TryParse(match.Value, CultureInfo.InvariantCulture, out var number) || number <= 0)
        {
            return 0;
        }
        var normalized = value.ToLowerInvariant();
        var multiplier = normalized.Contains("小时") || normalized.Contains("hour") ||
            Regex.IsMatch(normalized, @"(^|[^a-z])h([^a-z]|$)") ? 60 : 1;
        return Math.Max(1, (int)Math.Round(number * multiplier));
    }

    private void PruneWindows(DateTimeOffset now)
    {
        while (_typingWindow.TryPeek(out var item) && now - item.Time > TimeSpan.FromSeconds(60))
        {
            _typingWindow.Dequeue();
        }
        while (_actionWindow.TryPeek(out var action) && now - action.Time > TimeSpan.FromSeconds(60))
        {
            _actionWindow.Dequeue();
        }
        while (_activeTypingSecondMarks.TryPeek(out var mark) && now - mark > TimeSpan.FromSeconds(60))
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        {
            _activeTypingSecondMarks.Dequeue();
        }
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    }

    private void ClearExpiredVisual(DateTimeOffset now)
    {
        if (_visualModeExpiresAt is { } expiry && now >= expiry)
        {
            _visualMode = null;
            _visualModeExpiresAt = null;
            _visualDetail = null;
        }
    }

    private void RolloverIfNeeded(DateTimeOffset now)
    {
        var key = DayKey(now);
        if (key == _dayKey)
        {
            return;
        }
        SaveRecords();
        _dayKey = key;
        ResetCounters();
        ApplyRecord(_records.GetValueOrDefault(_dayKey));
        _reminderKeys.Clear();
    }

    private void ResetCounters()
    {
        IsOnBreak = false;
        IsBreakTimerPaused = false;
        BreakRemaining = 0;
        WorkSeconds = 0;
        BreakSeconds = 0;
        AiDoneCount = 0;
        WaterCheckins = 0;
        TotalPrintableKeys = 0;
        TotalCorrectionKeys = 0;
        ActiveTypingSeconds = 0;
        TotalActions = 0;
        TotalEffectiveActions = 0;
        _lastTypingAt = null;
        _typingWindow.Clear();
        _activeTypingSecondMarks.Clear();
        _actionWindow.Clear();
    }

    private void ApplyRecord(DailyRecord? record)
    {
        if (record is null)
        {
            return;
        }
        WorkSeconds = record.WorkSeconds;
        BreakSeconds = record.BreakSeconds;
        AiDoneCount = record.AiDoneCount;
        WaterCheckins = record.WaterCheckins;
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        TotalPrintableKeys = record.PrintableKeys;
        TotalCorrectionKeys = record.CorrectionKeys;
        ActiveTypingSeconds = record.ActiveTypingSeconds;
        TotalActions = record.ActionCount;
        TotalEffectiveActions = record.EffectiveActionCount;
    }

    private DailyRecord SnapshotRecord(string key) => new()
    {
        Date = key,
        WorkSeconds = WorkSeconds,
        BreakSeconds = BreakSeconds,
        AiDoneCount = AiDoneCount,
        WaterCheckins = WaterCheckins,
        PrintableKeys = TotalPrintableKeys,
        CorrectionKeys = TotalCorrectionKeys,
        ActiveTypingSeconds = ActiveTypingSeconds,
        ActionCount = TotalActions,
        EffectiveActionCount = TotalEffectiveActions
    };

    private static DailyRecord AddRecords(DailyRecord left, DailyRecord right) => new()
    {
        Date = "total",
        WorkSeconds = left.WorkSeconds + right.WorkSeconds,
        BreakSeconds = left.BreakSeconds + right.BreakSeconds,
        AiDoneCount = left.AiDoneCount + right.AiDoneCount,
        WaterCheckins = left.WaterCheckins + right.WaterCheckins,
        PrintableKeys = left.PrintableKeys + right.PrintableKeys,
        CorrectionKeys = left.CorrectionKeys + right.CorrectionKeys,
        ActiveTypingSeconds = left.ActiveTypingSeconds + right.ActiveTypingSeconds,
        ActionCount = left.ActionCount + right.ActionCount,
        EffectiveActionCount = left.EffectiveActionCount + right.EffectiveActionCount
    };

    private void SaveSettings() => _store.SaveSettings(Settings);

    private void SaveRecords()
    {
        _records[_dayKey] = SnapshotRecord(_dayKey);
        _store.SaveRecords(_records);
    }

    private Dictionary<string, DailyRecord> RecordsSnapshot()
    {
        var snapshot = new Dictionary<string, DailyRecord>(_records, StringComparer.Ordinal);
        snapshot[_dayKey] = SnapshotRecord(_dayKey);
        return snapshot;
    }

    private static string DayKey(DateTimeOffset value) => value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
}
