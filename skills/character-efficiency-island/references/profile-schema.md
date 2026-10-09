# Profile schema

Use `templates/character-profile.json` as the intake form. Every fork should define:

- display name, app name, menu-bar short name and unique macOS Bundle ID;
- Windows `appName`, `storageId` and `mutexId` when Windows is included;
- titles/details for working, break, idle, alert, AI and water states;
- four reminder names, schedules and enabled defaults;
- the exact image filename for each state.

Companion forks may add a separate YAML profile with executable name, Bundle ID, data root, tracker title and source/target directories. Keep all identifiers unique to the fork.
