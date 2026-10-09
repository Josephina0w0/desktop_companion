# 图片槽位与布置

模板的关键约定是：桌宠/小岛使用完整的 Q 版图，控制面板使用完整的正比立绘。两类图片不能互换。所有图片都应是透明 PNG，源图不能裁掉人物或道具；站位由统一的尺寸和边距控制。

## macOS 灵动岛

把 19 张 PNG 放入：

```text
Sources/CharacterEfficiencyIsland/Assets/
```

| 文件 | 用途 |
| --- | --- |
| `working.png` | 工作中小岛/桌宠 |
| `break.png` | 休息倒计时 |
| `idle.png` | 无活动后的待命 |
| `alert.png` | 普通提醒 |
| `ai.png` | AI 完成 |
| `water.png` | 喝水 |
| `reminder-first.png` | 第一条定时提醒 |
| `reminder-second.png` | 第二条定时提醒 |
| `reminder-third.png` | 第三条定时提醒 |
| `reminder-fourth.png` | 第四条定时提醒 |
| `panel-working.png` | 工作面板正比人物 |
| `panel-break.png` | 休息面板正比人物 |
| `panel-idle.png` | 待命面板正比人物 |
| `panel-water.png` | 喝水面板正比人物 |
| `panel-ai.png` | AI 面板正比人物 |
| `panel-reminder-second.png` | 第二条提醒面板 |
| `panel-reminder-third.png` | 第三条提醒面板 |
| `panel-reminder-fourth.png` | 第四条提醒面板 |
| `statusIcon.png` | 菜单栏与 App 图标来源 |

建议画布至少 800×800（小岛）或 900×1400（面板），人物四周保留约 5%—10% 透明安全边距。脚本会等比缩放；不要为了“对齐”把人物画进不同大小的画布。

面板人物位置在 `Sources/CharacterEfficiencyIsland/main.swift` 的 `characterPlacement(for:)` 中调整：

- `height`：可见高度，越大人物越大。
- `bottom`：距绘图区底部的距离，越大人物越往上。
- `trailing`：距右侧的距离，越小越靠右；负数表示继续伸出右边。

应以人物可见轮廓为准调参，而不是比较 PNG 外框尺寸。头、脚、衣摆和手持道具都必须完整显示。

## macOS Companion

桌宠起始工程位于：

```text
companion-pack/skills/character-companion-builder/assets/companion-starter/
```

复制后，把小岛/桌宠的 Q 图放入 `Sources/Companion/Assets/EfficiencyIsland/`，把控制面板正比图放入对应的 `panel-*` 槽位；Tracker 的角色图放入 `Sources/Companion/Assets/Tracker/`。桌宠图使用底部对齐，人物的可见底边应贴近固定的指标条，不要按图片画布中心对齐。

## Windows 资料包

自定义 Windows 版本使用：

```text
Windows/CharacterPacks/<slug>/Assets/
```

文件名与 macOS 槽位相同，仍是 19 张 PNG。`working`、`break`、`idle`、`alert`、`ai`、`water`、`reminder-*` 是 Q 版状态图；`panel-*` 是面板正比图；`statusIcon` 是托盘图标。默认 `generic` 不需要复制资料包，直接复用根目录中性占位图。

## 检查清单

- 两张状态图的画布尺寸可以不同，但人物可见高度和底边要保持一致。
- 相邻状态切换时，脚底/椅子/道具不应跳动；必要时先裁出一致的透明安全边距。
- 小岛和桌宠不应使用 `panel-*`；控制面板不应使用 Q 版槽位。
- 运行应用逐一检查工作、休息、待命、喝水、AI 和四种提醒，而不是只看文件名。
- 公开发布前确认所有素材拥有再分发授权。
