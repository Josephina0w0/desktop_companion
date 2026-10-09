# 文案与应用标识清单

先复制 `templates/character-profile.json`，把它当作定制输入表。它记录“需要准备什么”，不会自动写回 Swift 或 Windows 配置。

## 必填标识

| 项目 | 说明 |
| --- | --- |
| 显示名 | 面板、通知和权限列表看到的名字 |
| macOS App 名 | `build_app.sh`、`Packaging/Info.plist` 和输出文件名 |
| macOS Bundle ID | 英文小写、数字、点或连字符组成的唯一 ID |
| Windows `appName` | 托盘、EXE、ZIP 和面板标题 |
| Windows `storageId` | `%LOCALAPPDATA%` 下的独立记录目录 |
| Windows `mutexId` | 防止同一版本重复启动的唯一标识 |

不要复用另一个应用的 Bundle ID、storageId 或 mutexId，否则权限、设置和历史记录可能互相覆盖。

## 核心状态

为每个状态准备短标题和一句提示，标题建议不超过 10 个中文字符，提示建议不超过 32 个中文字符：

| 状态 | 必填文案 |
| --- | --- |
| 工作中 | 标题、细节、顶部小岛短句 |
| 休息中 | 标题、倒计时提示、结束休息提示 |
| 待命中 | 标题、无活动提示 |
| 普通提醒 | 标题、提醒细节 |
| AI 完成 | 标题、验收提示 |
| 喝水 | 标题、喝水提示 |

四类定时提醒还需要名称、默认时间/间隔、启用状态和触发文案。时间可写 `12:00`、`19:00`、`每 30 分钟` 或 `每 2 小时`。

## 操作反馈

建议一并准备：开始休息、结束休息、暂停/继续、休息自然结束、喝水打卡、清零今日、清空全部、恢复小岛、重置人物大小、输入监控未授权、权限重置和 AI 桥接完成等短句。没有写全时可以保留模板的中性默认文案。

## 语气说明

用 3—5 个词描述语气，例如：

```text
性格：冷静、可靠、句子短
称呼用户：你
催促强度：温和
避免：制造焦虑、过度卖萌、连续感叹号
```

同一套词应同时用于 macOS 和 Windows，避免两个平台看起来像不同产品。

## 改动位置

- macOS 逻辑、文案和面板位置：`Sources/CharacterEfficiencyIsland/main.swift`
- macOS 名称、Bundle ID 和权限说明：`Packaging/Info.plist`
- macOS 产物名和资源 Bundle：`build_app.sh`
- Windows 文案、提醒和面板位置：`Windows/CharacterEfficiencyIsland.Windows/profile.json` 或你的资料包 `Windows/CharacterPacks/<slug>/profile.json`
- Companion 的产品标识与文案：复制后的 `Package.swift`、`build_app.sh`、`Packaging/Info.plist` 和 `Sources/Companion/`
