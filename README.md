# 赛博陪伴系列模板

这是一个不含任何独立人物成品的通用模板库：同一套状态、提醒、统计和本地数据逻辑，提供 macOS 与 Windows 两个平台的灵动岛和桌宠外壳。仓库只保留通用代码、示例占位图、资源槽位、构建脚本和定制指南；人物素材、个人记录和成品包都不在库内。作者/上传者：小红书[@海狮没有论文](https://xhslink.cn/m/5QjyCWDXJ2m)，抖音[@海狮没有论文](https://v.douyin.com/LJPU7iqkwWc/4@4.com)。

## 你会得到什么

- macOS Universal 灵动岛：菜单栏状态、工作/休息/待命、喝水、定时提醒、AI 完成提醒、输入统计和本地记录。
- macOS Companion 通用起始包：可拖动桌宠、正比控制面板、Tracker 和同一进程内的效率岛功能。
- Windows 11 通用工程：同一份代码可构建顶部/侧边灵动岛或自由拖动桌宠。
- 中性占位 PNG 和完整的图片槽位约定；你只需替换图片、文案、应用标识和资料目录。

仓库不包含任何具体角色名字、角色包或独立人物立绘。

## 最短上手路线

1. Fork 或下载本库。
2. 复制并填写 [templates/character-profile.json](templates/character-profile.json)。它是文案、提醒、图片槽位和应用标识的清单，不会自动修改程序。
3. 按 [图片与资源布置](docs/IMAGE_SLOTS.md) 准备透明 PNG，并覆盖 macOS 的 `Sources/CharacterEfficiencyIsland/Assets/`。
4. 在 `Packaging/Info.plist`、`build_app.sh` 和 Swift 源码中，把示例应用名、Bundle ID、存储目录和文案换成你的值。
5. 在 Mac 上运行：

   ```sh
   ./build_app.sh
   ```

   输出在 `dist/`，包括 `.app` 和 `.zip`。

6. Windows 用户按 [Windows 定制与构建](docs/WINDOWS.md) 创建自己的资料包，然后分别构建灵动岛和桌宠。

如果你不改代码，只想让编程 AI 帮你完成，直接复制 [AI 定制工作流](docs/AI_CUSTOMIZATION.md) 中的提示词，并把自己的图片和资料表一起交给它。

## macOS：灵动岛和桌宠

根目录 `Sources/CharacterEfficiencyIsland/` 是 macOS 灵动岛应用。`companion-pack/` 是独立的 macOS Companion 通用起始包，包含桌宠、Project Tracker、资源规范、构建脚本和发布检查。两者都只使用通用占位素材；替换图片时必须保持小岛/桌宠使用 Q 版槽位，控制面板使用正比人物槽位，不能混用。

```text
Sources/CharacterEfficiencyIsland/Assets/    macOS 灵动岛图片槽位
companion-pack/.../assets/companion-starter/ macOS 桌宠 + Tracker 起始工程
templates/character-profile.json              文案和标识资料表
docs/                                         定制、布置、构建和发布指南
```

## Windows：两个外壳、一个通用资料包

Windows 工程位于 `Windows/CharacterEfficiencyIsland.Windows/`。默认 `generic` 资料包直接使用根目录 macOS 占位图和 `Windows/CharacterEfficiencyIsland.Windows/profile.json`，不需要额外复制人物包。

```powershell
./Windows/build_windows.ps1 -Flavor dynamic-island -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor dynamic-island -Runtime win-x64

./Windows/build_windows.ps1 -Flavor companion -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor companion -Runtime win-x64
```

当你准备好自己的 Windows 资源后，在 `Windows/CharacterPacks/<slug>/` 放入 `profile.json` 和 19 张同名 PNG，再把构建命令加上 `-CharacterPack <slug>`。脚本不再内置任何独立人物列表，资料包由 fork 使用者自己维护。

## 功能与隐私

工作、休息、喝水、提醒、AI 完成和输入统计共用本地状态；键盘统计只保存数量、类别和时间，不保存具体键入内容。Mac 的记录位于 `~/Library/Application Support/CharacterEfficiencyIsland/`，Windows 位于 `%LOCALAPPDATA%\CharacterEfficiencyIsland\`。首次使用输入统计需要系统的输入监控/辅助功能权限。

## 目录速览

```text
Sources/CharacterEfficiencyIsland/        macOS 灵动岛通用源代码
Sources/CharacterEfficiencyIsland/Assets  macOS 19 个资源槽位（中性占位图）
companion-pack/                            macOS 桌宠与 Tracker 通用起始包
Windows/CharacterEfficiencyIsland.Windows Windows 11 通用 WPF 工程
Windows/CharacterPacks/                    你自己的 Windows 资料包目录（默认为空）
templates/character-profile.json           定制资料表
docs/                                      从图片准备到发布的完整指南
```

## 公开发布前

- 只使用你原创、已购买许可、公有领域或明确获授权的图片、字体和标志。
- 不提交 `.build/`、`dist/`、本地记录、权限文件或个人配置。
- Mac 运行 `scripts/verify_universal_app.sh`；Windows 运行 `verify_windows_package.ps1`。
- 检查每个状态都没有裁切、错位或把面板正比图误放进桌宠/小岛。

详细步骤见：

- [Fork 后的定制流程](docs/FORK_AND_CUSTOMIZE.md)
- [文案与应用标识](docs/COPYWRITING.md)
- [图片槽位与对齐](docs/IMAGE_SLOTS.md)
- [Windows 定制与构建](docs/WINDOWS.md)
- [AI 定制工作流](docs/AI_CUSTOMIZATION.md)
- [发布检查](docs/RELEASE.md)
