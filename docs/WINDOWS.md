# Windows 11：通用灵动岛与桌宠

Windows 工程使用一套 WPF 核心，同时提供两种外壳：`dynamic-island` 是顶部/侧边吸附的小岛，`companion` 是可以在桌面拖动和等比缩放的桌宠。两种外壳共用计时、提醒、输入统计、记录、托盘和控制面板。

## 运行要求

- Windows 11（x64 优先；脚本也接受 `win-arm64`）。
- .NET 10 SDK；发布为自包含 EXE，不要求最终用户另装 .NET。
- 输入统计需要 Windows 的输入监控权限/安全软件允许全局键鼠监听；程序不会保存具体输入内容。

## 先运行通用占位版

仓库没有任何人物包。默认 `generic` 直接使用 macOS 资源目录中的中性占位 PNG 和 `Windows/CharacterEfficiencyIsland.Windows/profile.json`：

```powershell
./Windows/build_windows.ps1 -Flavor dynamic-island -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor dynamic-island -Runtime win-x64

./Windows/build_windows.ps1 -Flavor companion -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor companion -Runtime win-x64
```

输出位于 `dist/windows/`，分别包含 `.exe` 和 `.zip`。第一次运行后可从托盘图标打开控制面板。

## 添加自己的资料包

在 `Windows/CharacterPacks/<slug>/` 创建一个目录，放入：

1. 从 `Windows/CharacterEfficiencyIsland.Windows/profile.json` 复制的 `profile.json`。
2. `Assets/` 目录中的 19 张透明 PNG，文件名必须是：

   ```text
   working.png, break.png, idle.png, alert.png, ai.png, water.png,
   reminder-first.png, reminder-second.png, reminder-third.png,
   reminder-fourth.png, panel-working.png, panel-break.png,
   panel-idle.png, panel-water.png, panel-ai.png,
   panel-reminder-second.png, panel-reminder-third.png,
   panel-reminder-fourth.png, statusIcon.png
   ```

3. `profile.json` 中唯一的 `appName`、`storageId`、`mutexId`、标题、细节和 `panelPlacements`。

构建时传入 slug：

```powershell
./Windows/build_windows.ps1 -Flavor dynamic-island -CharacterPack <slug> -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor dynamic-island -CharacterPack <slug> -Runtime win-x64
./Windows/build_windows.ps1 -Flavor companion -CharacterPack <slug> -Runtime win-x64
./Windows/verify_windows_package.ps1 -Flavor companion -CharacterPack <slug> -Runtime win-x64
```

脚本会在构建前检查 profile 和全部 19 张图；缺图或拼写不一致会直接失败。

## 图片和位置规则

- `working/break/idle/...` 是桌宠/小岛使用的 Q 版状态图。
- `panel-*` 是控制面板使用的正比人物图。
- `statusIcon.png` 是托盘与应用图标来源。
- 图片必须透明、完整、等比；不要在源图中裁掉头、脚、道具或桌宠的底部。
- 面板图位置通过 `profile.json` 的 `panelPlacements` 调整；小岛/桌宠缩放由窗口统一控制，不能为某个状态偷偷改窗口尺寸。

## 两种外壳的操作

### 灵动岛

- 拖动岛身后会吸附到屏幕顶部或左右边缘。
- 拖动右下角透明缩放区可按原比例缩放，范围约为 75%—160%。
- 双击休息状态可暂停/继续倒计时；点击托盘图标打开控制面板。

### 桌宠

- 拖动人物在桌面移动，释放时会限制在当前工作区内。
- 拖动右下角透明缩放区可等比缩放。
- 双击桌宠打开控制面板。

## 发布前检查

- 两种 Flavor 都能构建并通过验证脚本。
- 19 个资源槽位均能显示，Q/正比没有串位。
- 工作状态恢复、30 分钟待命、提醒、记录、托盘退出和再次启动均正常。
- ZIP 内的主程序名、应用名和 profile 的 `appName` 一致。
- 只分发你拥有许可的图片和文案。
