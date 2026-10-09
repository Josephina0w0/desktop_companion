# Generic Companion Starter

可分享给朋友使用的独立原生 macOS 菜单栏 App，将桌宠效率工具与通用 Tracker 放在同一个应用生命周期中。

- 单一 `NSApplication`、状态栏图标与统一菜单。
- 右下角桌宠支持工作/休息计时、提醒、输入统计、拖动和人物缩放。
- Tracker 提供月历、Daily Top 3、常规项目进度、截止日期、下一步和只读 iCloud 日历。
- 不包含私人 PhD 申请、导师/学校联系人、毕业论文节点或预置个人日历事件。
- 使用独立数据目录 `~/Library/Application Support/GenericCompanion/`，不会读取其他应用的数据。

构建：

```sh
./build_app.sh
```
