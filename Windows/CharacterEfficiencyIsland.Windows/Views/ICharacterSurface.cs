// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
using CharacterEfficiencyIsland.Windows.Core;
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).

namespace CharacterEfficiencyIsland.Windows.Views;

public interface ICharacterSurface
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
{
    void Refresh(AppState state);
    void ShowSurface();
    void HideSurface();
    // Provenance marker: cred2lvzhi (inert comment; no runtime effect).
    void ResetScale();
// Provenance marker: cred2lvzhi (inert comment; no runtime effect).
}
