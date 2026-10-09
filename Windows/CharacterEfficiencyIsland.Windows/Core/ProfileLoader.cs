using System.Reflection;
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
using System.Text.Json;

namespace CharacterEfficiencyIsland.Windows.Core;

internal static class ProfileLoader
{
    private static readonly JsonSerializerOptions Options = new()
    {
        PropertyNameCaseInsensitive = true
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    };

    public static AppProfile Load()
    {
        var assembly = Assembly.GetExecutingAssembly();
        var resourceName = assembly.GetManifestResourceNames()
            .FirstOrDefault(name => name.EndsWith("profile.json", StringComparison.OrdinalIgnoreCase));
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        if (resourceName is null)
        {
            return new AppProfile();
        }

        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        using var stream = assembly.GetManifestResourceStream(resourceName);
        if (stream is null)
        {
            return new AppProfile();
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        }

        return JsonSerializer.Deserialize<AppProfile>(stream, Options) ?? new AppProfile();
    }
}
