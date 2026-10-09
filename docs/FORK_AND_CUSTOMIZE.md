# Fork 后的定制流程

这份流程适用于从 `lvzhi_companiontemplates` fork 出来的第一个角色或品牌版本。模板本身只提供通用程序和中性占位图；你的 fork 应该把它变成一个独立应用，而不是直接覆盖上游库。

## 1. 创建自己的工作副本

```sh
git clone https://github.com/<你的用户名>/<你的仓库>.git
cd <你的仓库>
git checkout -b customize/<你的代号>
```

先确认 `git status` 干净，并保留一份未经修改的资料表作为回滚参考。

## 2. 先填资料表，再改代码

复制 `templates/character-profile.json`，为以下项目准备最终值：

- 显示名、应用名、菜单栏简称。
- macOS Bundle ID、Windows `storageId` 和 `mutexId`。
- 工作、休息、待命、提醒、AI 完成、喝水的标题和细节文案。
- 四条提醒的名称、时间和默认开关。
- 每个状态对应的图片文件名。

Bundle ID、存储目录和互斥锁标识必须是你自己的唯一值，否则两个版本可能共用权限或记录。

## 3. 准备并布置 macOS 图片

把透明 PNG 按 [图片槽位说明](IMAGE_SLOTS.md) 放入 `Sources/CharacterEfficiencyIsland/Assets/`。小岛和桌宠使用完整的 Q 版素材；控制面板使用完整的正比人物素材。源图不能被裁切，站位通过代码中的尺寸与边距参数调整。

接着检查：

```text
Sources/CharacterEfficiencyIsland/main.swift  状态、文案和面板位置
Packaging/Info.plist                           App 名称、Bundle ID、权限说明
build_app.sh                                   App 名、可执行文件和资源 Bundle 名
```

不要把个人记录、截图、下载目录或绝对路径写进工程。

## 4. 准备 macOS Companion

复制 `companion-pack/skills/character-companion-builder/assets/companion-starter/` 到你想要的独立目录（例如 `companion/`），然后按其中的 README 和 profile 模板修改：

- `Package.swift` 和 `build_app.sh` 中的产品名、可执行文件、资源 Bundle。
- `Packaging/Info.plist` 中的显示名和 Bundle ID。
- `Sources/Companion/Assets/EfficiencyIsland/` 的状态图与 `Tracker/` 的角色图。
- 数据根目录、Tracker 标题和状态文案。

桌宠始终使用 Q 版资源并底部对齐到指标条；控制面板始终使用正比资源。不同宽高比的 PNG 不要用额外的透明边距“硬凑”位置，优先调整统一的 fit/bottom 参数。

## 5. 准备 Windows 资料包

默认构建可直接运行 `generic`，因此你可以先验证功能。准备自己的素材时，新建：

```text
Windows/CharacterPacks/<slug>/
├── profile.json
└── Assets/
    ├── working.png
    ├── break.png
    ├── idle.png
    ├── alert.png
    ├── ai.png
    ├── water.png
    ├── reminder-first.png
    ├── reminder-second.png
    ├── reminder-third.png
    ├── reminder-fourth.png
    ├── panel-working.png
    ├── panel-break.png
    ├── panel-idle.png
    ├── panel-water.png
    ├── panel-ai.png
    ├── panel-reminder-second.png
    ├── panel-reminder-third.png
    ├── panel-reminder-fourth.png
    └── statusIcon.png
```

`profile.json` 可以从 `Windows/CharacterEfficiencyIsland.Windows/profile.json` 复制，再替换名称、标识、文案和 `panelPlacements`。图片文件名必须完全匹配，大小写也不能变。

## 6. 本机构建与验收

macOS：

```sh
./build_app.sh
scripts/verify_universal_app.sh "dist/角色效率岛.app"
scripts/verify_universal_app.sh "dist/角色效率岛.zip"
```

Windows（在 Windows 11 + .NET 10 SDK 中）：

```powershell
./Windows/build_windows.ps1 -Flavor dynamic-island -CharacterPack <slug> -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor dynamic-island -CharacterPack <slug> -Runtime win-x64

./Windows/build_windows.ps1 -Flavor companion -CharacterPack <slug> -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor companion -CharacterPack <slug> -Runtime win-x64
```

逐一检查工作、休息、待命、喝水、AI 和四种提醒；确认 Q 版没有出现在控制面板，正比图没有出现在桌宠/小岛。确认拖动、缩放、权限提示、记录持久化和退出重启都正常。

## 7. 提交和发布

```sh
git add .
git commit -m "Customize generic companion template"
git push -u origin customize/<你的代号>
```

公开发布前再次检查素材授权，并确认仓库没有 `.build/`、`dist/`、本地数据库、钥匙串内容或个人绝对路径。
