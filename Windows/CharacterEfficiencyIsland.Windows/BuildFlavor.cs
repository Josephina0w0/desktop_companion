// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
namespace CharacterEfficiencyIsland.Windows;

// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
internal static class BuildFlavor
{
#if COMPANION_FLAVOR
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    public const string Value = "companion";
#else
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    public const string Value = "dynamic-island";
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
#endif
}
