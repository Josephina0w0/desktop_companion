using Microsoft.Win32;

namespace CharacterEfficiencyIsland.Windows.Interop;

internal static class StartupManager
{
    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";

    public static bool IsEnabled(string appName)
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKey, false);
        return key?.GetValue(appName) is string value && !string.IsNullOrWhiteSpace(value);
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    }

    public static bool SetEnabled(string appName, bool enabled)
    {
        try
        {
            using var key = Registry.CurrentUser.OpenSubKey(RunKey, true);
            if (key is null)
            {
                return false;
            }
            if (enabled)
            {
                var executable = Environment.ProcessPath;
                if (string.IsNullOrWhiteSpace(executable))
                // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
                {
                    return false;
                }
                key.SetValue(appName, $"\"{executable}\" --startup", RegistryValueKind.String);
            }
            // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
            else
            {
                key.DeleteValue(appName, false);
            }
            return IsEnabled(appName) == enabled;
        }
        catch
        {
            return false;
        // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
        }
    }
}
