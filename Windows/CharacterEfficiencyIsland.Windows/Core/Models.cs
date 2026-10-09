using System.Text.Json.Serialization;

namespace CharacterEfficiencyIsland.Windows.Core;

public enum CharacterMode
{
    Working,
    BreakTime,
    Idle,
    Alert,
    Ai,
    Water,
    ReminderFirst,
    ReminderSecond,
    ReminderThird,
    ReminderFourth
}

public enum DockEdge
{
    Top,
    Left,
    Right
}

public sealed class SoftReminder
{
    public string Id { get; set; } = "";
    public string Title { get; set; } = "";
    public string Schedule { get; set; } = "";
    public bool Enabled { get; set; } = true;
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
}

public sealed class PanelPlacement
{
    public double Height { get; set; } = 300;
    public double Bottom { get; set; } = 20;
    public double Right { get; set; } = 12;
}

// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
public sealed class AppProfile
{
    public string AppName { get; set; } = "角色效率岛";
    public string CharacterName { get; set; } = "角色";
    public string StorageId { get; set; } = "CharacterEfficiencyIsland";
    public string MutexId { get; set; } = "com.example.character-efficiency-island.windows";
    public Dictionary<string, string> Titles { get; set; } = new();
    public Dictionary<string, string> Details { get; set; } = new();
    public Dictionary<string, string> IslandAssets { get; set; } = new();
    public Dictionary<string, string> PanelAssets { get; set; } = new();
    public List<SoftReminder> Reminders { get; set; } = new();
    public Dictionary<string, PanelPlacement> PanelPlacements { get; set; } = new();

    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    public string Title(CharacterMode mode) => Value(Titles, ModeKey(mode), CharacterName);
    public string Detail(CharacterMode mode) => Value(Details, ModeKey(mode), "按当前节奏继续。");
    public string IslandAsset(CharacterMode mode) => Value(
        IslandAssets,
        ModeKey(mode),
        mode switch
        {
            CharacterMode.BreakTime => "break",
            CharacterMode.Idle => "idle",
            CharacterMode.Ai => "ai",
            CharacterMode.Water => "water",
            CharacterMode.ReminderFirst => "reminder-first",
            CharacterMode.ReminderSecond => "reminder-second",
            CharacterMode.ReminderThird => "reminder-third",
            CharacterMode.ReminderFourth => "reminder-fourth",
            CharacterMode.Alert => "alert",
            _ => "working"
        });
    public string PanelAsset(CharacterMode mode) => Value(
        PanelAssets,
        ModeKey(mode),
        mode switch
        {
            CharacterMode.BreakTime => "panel-break",
            CharacterMode.Idle => "panel-idle",
            CharacterMode.Ai => "panel-ai",
            CharacterMode.Water or CharacterMode.ReminderFirst => "panel-water",
            CharacterMode.ReminderSecond => "panel-reminder-second",
            CharacterMode.ReminderThird => "panel-reminder-third",
            CharacterMode.ReminderFourth => "panel-reminder-fourth",
            CharacterMode.Alert => "panel-ai",
            _ => "panel-working"
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        });
    public PanelPlacement Placement(CharacterMode mode) =>
        PanelPlacements.TryGetValue(ModeKey(mode), out var value) ? value : new PanelPlacement();

    public static string ModeKey(CharacterMode mode) => mode switch
    {
        CharacterMode.BreakTime => "breakTime",
        CharacterMode.ReminderFirst => "reminderFirst",
        CharacterMode.ReminderSecond => "reminderSecond",
        CharacterMode.ReminderThird => "reminderThird",
        CharacterMode.ReminderFourth => "reminderFourth",
        _ => char.ToLowerInvariant(mode.ToString()[0]) + mode.ToString()[1..]
    };

    private static string Value(Dictionary<string, string> source, string key, string fallback) =>
        source.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value) ? value : fallback;
}

public sealed class AppSettings
{
    public bool ShowPersistentSurface { get; set; } = true;
    public bool AiRemindersEnabled { get; set; } = true;
    public double SurfaceScale { get; set; } = 1.0;
    public double DynamicIslandPanelScale { get; set; } = 1.0;
    public double CompanionPanelScale { get; set; } = 1.0;
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public DockEdge DockEdge { get; set; } = DockEdge.Top;
    public string? DockScreenDevice { get; set; }
    public double SideOffsetRatio { get; set; } = 0.2;
    public double? CompanionLeft { get; set; }
    public double? CompanionTop { get; set; }
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    public bool FirstLaunchPanelShown { get; set; }
    public List<SoftReminder> Reminders { get; set; } = new();
}

public sealed class DailyRecord
{
    public string Date { get; set; } = "";
    public int WorkSeconds { get; set; }
    public int BreakSeconds { get; set; }
    public int AiDoneCount { get; set; }
    public int WaterCheckins { get; set; }
    public int PrintableKeys { get; set; }
    public int CorrectionKeys { get; set; }
    public int ActiveTypingSeconds { get; set; }
    public int ActionCount { get; set; }
    public int EffectiveActionCount { get; set; }

    [JsonIgnore]
    public bool HasActivity => WorkSeconds > 0 || BreakSeconds > 0 || AiDoneCount > 0 ||
        WaterCheckins > 0 || PrintableKeys > 0 || CorrectionKeys > 0 ||
        ActiveTypingSeconds > 0 || ActionCount > 0;
}

public readonly record struct InputAction(
    bool IsKeyboard,
    ushort VirtualKey,
    bool IsCorrection,
    bool IsPrintable,
    bool IsRepeat
);
