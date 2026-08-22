# Window Keybindings

一套面向键盘流桌面的**窗口、工作区、搜索与布局交互规范草案**。

> 核心目标：**创建窗口是自由的；创建后可以遗忘。切换时只需要知道“我要什么”，不需要记住“它现在在哪里”。**

## 阅读方式

本仓库现在分成两层：

- [`index.html`](./index.html)：**人类主入口**。单页交互式规范，按“原则 → Workspace → Role → Search → Layout → 快捷键 → 后端 → 待讨论”递进；所有细节以卡片展开，可筛选、搜索、展开/收起。
- [`SPEC.md`](./SPEC.md)：完整原始规范文本，适合全文检索、diff 与后续实现引用。
- [`REFERENCES.md`](./REFERENCES.md)：niri、Hyprland、Noctalia 等现有设计对本规范的影响与参考依据。

`index.html` 是自包含文件，不需要构建步骤。直接用浏览器打开即可；如果未来启用 GitHub Pages，也可以直接作为站点首页。

## 当前状态

**Draft v0.1 — 只讨论设计，不实现。**

目前已经基本确定的是：

- 位置不是窗口身份；后台窗口顺序不要求用户记忆。
- 已知高频目标使用 role 直接寻址，长尾目标使用名称搜索。
- Workspace 应有名字，`1..9` 只是快速槽位而不是身份。
- 切换/复用与明确新建必须是两个不同意图。
- Local role 与 Global Main role 是不同作用域。
- Global Main 默认把窗口拉到当前上下文，而不是把用户送去窗口原来的位置。
- `Mod+Tab` 只承担“回到刚才”的时间导航。
- 空间方向只在窗口同时可见时承担语义。

最需要继续人工讨论的是：

- plain role activation 到底只 focus、替换 pane，还是回到 solo 主视图；
- compose 的默认方向与比例，以及如何低成本表达 left/right/up/down；
- `Mod+Space` 与 `Mod+D` 的最终 switch-or-create / force-new 交互；
- workspace slot、多显示器、global-main 漫游与 local role 自动认领规则。

在这些问题达成共识前，不应把 niri、Hyprland 或任何 compositor 的实现限制写成规范本身。
