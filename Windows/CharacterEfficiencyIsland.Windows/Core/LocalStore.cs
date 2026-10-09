using System.IO;
using System.Text.Json;
using System.Text.Json.Serialization;

// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
namespace CharacterEfficiencyIsland.Windows.Core;

internal sealed class LocalStore
{
    private readonly string _folder;
    private readonly string _settingsPath;
    private readonly string _recordsPath;
    private readonly JsonSerializerOptions _options = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter() }
    };

    public LocalStore(AppProfile profile, string flavor)
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    {
        var localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        _folder = Path.Combine(localAppData, profile.StorageId, flavor);
        _settingsPath = Path.Combine(_folder, "settings.json");
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        _recordsPath = Path.Combine(_folder, "daily-records.json");
    }

    public string Folder => _folder;

    public AppSettings LoadSettings(AppProfile profile)
    {
        var settings = Read<AppSettings>(_settingsPath) ?? new AppSettings();
        if (settings.Reminders.Count == 0)
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        {
            settings.Reminders = profile.Reminders.Select(CloneReminder).ToList();
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        }
        else
        {
            settings.Reminders = NormalizeReminders(settings.Reminders, profile.Reminders);
        }
        settings.SurfaceScale = Math.Clamp(settings.SurfaceScale, 0.75, 1.60);
        settings.DynamicIslandPanelScale = Math.Clamp(settings.DynamicIslandPanelScale, 0.65, 1.60);
        settings.CompanionPanelScale = Math.Clamp(settings.CompanionPanelScale, 0.65, 1.60);
        settings.SideOffsetRatio = Math.Clamp(settings.SideOffsetRatio, 0, 1);
        return settings;
    }

    public Dictionary<string, DailyRecord> LoadRecords() =>
        Read<Dictionary<string, DailyRecord>>(_recordsPath) ?? new Dictionary<string, DailyRecord>();

    public void SaveSettings(AppSettings settings) => Write(_settingsPath, settings);
    public void SaveRecords(Dictionary<string, DailyRecord> records) => Write(_recordsPath, records);

    private T? Read<T>(string path)
    {
        try
        {
            return File.Exists(path)
                ? JsonSerializer.Deserialize<T>(File.ReadAllText(path), _options)
                : default;
        }
        catch
        {
            return default;
        }
    }

    private void Write<T>(string path, T value)
    {
        Directory.CreateDirectory(_folder);
        var temporary = path + ".tmp";
        File.WriteAllText(temporary, JsonSerializer.Serialize(value, _options));
        File.Move(temporary, path, true);
    }

    private static List<SoftReminder> NormalizeReminders(
        IEnumerable<SoftReminder> stored,
        IEnumerable<SoftReminder> defaults)
    {
        var storedById = stored.ToDictionary(item => item.Id, StringComparer.OrdinalIgnoreCase);
        return defaults.Select(item =>
        {
            if (!storedById.TryGetValue(item.Id, out var saved))
            {
                return CloneReminder(item);
            }
            if (item.Id.Equals("water", StringComparison.OrdinalIgnoreCase))
            {
                saved.Title = item.Title;
            }
            return saved;
        }).ToList();
    }

    private static SoftReminder CloneReminder(SoftReminder item) => new()
    {
        Id = item.Id,
        Title = item.Title,
        Schedule = item.Schedule,
        Enabled = item.Enabled
    };
}
