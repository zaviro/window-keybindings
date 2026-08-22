# Window Keybindings

一套面向键盘流桌面的**窗口、工作区与搜索寻址规范草案**。

当前阶段只定义用户语义与暂定键位，不实现 compositor 配置。目标不是替代 niri / Hyprland 的窗口管理能力，而是在其上增加一层更低记忆负担的**语义寻址**。

## 当前核心模型

只保留三种主要寻址方式：

1. **知道角色** → 直接 role 键，例如 `Mod+B`、`Mod+T`。
2. **知道名字** → `Mod+D` 打开统一搜索，输入 2–3 个字符选择 window / application / workspace。
3. **只想回到刚才** → `Mod+Tab` 使用最近窗口历史。

窗口的物理位置、创建顺序和 MRU 距离都不是身份。

## 当前暂定键位

| 键 | 语义 | 状态 |
|---|---|---|
| `Mod+D` | Noctalia 统一搜索入口；窗口可跳转，应用可启动，后续加入 workspace | 暂定 |
| `Mod+B` | 当前 workspace 的 browser；已有则跳转，没有则创建 | 暂定 |
| `Mod+T` | 当前 workspace 的 terminal；已有则跳转，没有则创建 | 暂定；沿用 niri 的 T=Terminal |
| `Mod+Alt+B` | global-main browser；拉到当前 workspace，没有则创建 | 暂定 |
| `Mod+Alt+T` | global-main terminal；拉到当前 workspace，没有则创建 | 暂定 |
| `Mod+E` | Editor role 槽位 | **保留但暂不绑定** |
| `Mod+A` | AI / assistant role 槽位 | **保留但暂不绑定** |
| `Mod+Tab` | 最近窗口 / 回到刚才 | 保留 niri 原生语义 |

`Mod+Space` 不再作为本规范入口；`Mod+Shift+角色键 = compose` 的方案已删除。

## 原生窗口管理能力

niri 已经成熟且好用的窗口管理键原则上全部保留，包括：

- `Mod+O / Q / F / R / V / Shift+F / Tab`；
- 方向焦点；
- 窗口/列移动；
- workspace 切换与重排；
- consume / expel；
- resize / preset width；
- floating、maximize、fullscreen 等。

这些是**空间操作与回退层**，不需要因为语义寻址而删除。

## Workspace

长期 workspace 应有名字；`1..9` 只是快速槽位，不是身份。例如：

```text
1 → main
2 → window-keybindings
3 → learning
```

忘记数字时仍应能通过名称搜索进入。

## 文档

- [`index.html`](./index.html)：面向人的交互式草案入口。
- [`SPEC.md`](./SPEC.md)：完整规范与设计理由。
- [`REFERENCES.md`](./REFERENCES.md)：niri、Hyprland、Noctalia 的参考依据。

当前状态：**Draft v0.2**。