# Upstream References

本文记录本规范借鉴的**现有快捷键语义与 compositor 能力**。目的不是证明存在某个统一标准，而是区分：

- 已经被成熟桌面反复验证的交互习惯；
- 本仓库在这些习惯之上的新组合。

资料核对日期：2026-08-22。

---

# 1. niri

## 1.1 默认快捷键语法

官方 Getting Started：

https://niri-wm.github.io/niri/Getting-Started.html

niri 默认明确总结了一条很好的 modifier 语法：

> 如果某个快捷键负责“切换到那里”，加 `Ctrl` 通常就负责“把当前窗口/列移动到那里”。

当前官方主要默认键包括：

```text
Mod+T                 terminal
Mod+D                 application launcher
Mod+Q                 close window
Mod+Left/Right        focus column
Mod+Up/Down           focus window in column
Mod+Ctrl+方向         move window/column
Mod+PageUp/PageDown   workspace up/down
Mod+Ctrl+PageUp/Down  move column to workspace
Mod+1..9              workspace index
Mod+R                 column width preset
Mod+Shift+F           fullscreen
Mod+V                 floating toggle
```

### 对本规范的影响

保留：

- `Mod` 作为窗口系统级主修饰键；
- `Mod+T` 的 terminal 肌肉记忆；
- `Mod+D` 的“启动应用”语义，但进一步收窄为 deliberate create；
- `Mod+Q` close；
- `Mod+Shift+F` true fullscreen；
- `Mod+V` floating；
- `Ctrl = move/send` 的 modifier grammar；
- `Mod+1..9` 作为 workspace 快速入口。

改变：

- 不把 `Mod+方向` 当作寻找后台窗口的主要手段；
- 不把 workspace 数字 index 当作真正身份。

---

## 1.2 Named Workspaces

官方文档：

https://niri-wm.github.io/niri/Configuration%3A-Named-Workspaces.html

https://niri-wm.github.io/niri/Workspaces.html

niri 支持：

```text
workspace "browser"
focus-workspace "browser"
```

named workspace 即使为空也会保留，而普通动态 workspace 的 index 只是当前位置。

这直接支持本规范的判断：

> **workspace name 是身份；数字/位置只是快捷寻址。**

---

## 1.3 Recent Windows

官方文档：

https://niri-wm.github.io/niri/Configuration%3A-Recent-Windows.html

自 25.11 起 niri 原生提供 recent-window switcher，默认包含：

```text
Alt+Tab
Alt+Shift+Tab
Mod+Tab
Mod+Shift+Tab
```

并可按：

- all；
- output；
- workspace；
- current app-id

过滤。

### 对本规范的影响

这证明 `Tab` 很适合表达**时间历史**。

本规范因此保留：

```text
Mod+Tab = 回到刚才 / recent
```

但明确拒绝把 MRU 当作已知应用的主要寻址方式。

---

## 1.4 IPC

官方文档：

https://niri-wm.github.io/niri/IPC.html

Action API：

https://niri-wm.github.io/niri/niri_ipc/enum.Action.html

niri IPC 提供稳定 JSON/programmatic access，包括：

- windows；
- workspaces；
- focused window；
- event stream；
- focus window by ID；
- move window to workspace；
- focus workspace by name；
- floating/tiling/fullscreen 等动作。

### 对本规范的影响

因此 niri 的滚动布局并不阻止建立：

- semantic role；
- named workspace；
- global-main summon；
- search by name；
- focus-or-create。

主要缺口是高级二维 composition 需要额外适配。

---

# 2. Hyprland

## 2.1 Workspace addressing

官方 dispatcher 文档：

https://wiki.hypr.land/Configuring/Dispatchers/

Hyprland workspace 可按多种方式寻址，包括：

- 数字 ID；
- relative ID；
- name；
- previous；
- empty；
- special workspace。

例如：

```text
name:Web
name:Anime
special:name
```

### 对本规范的影响

Hyprland 说明 named workspace 和数字快捷入口可以自然并存，因此本规范将：

```text
Mod+1..9
```

定义为快速 slot，而不是 workspace 的唯一身份。

---

## 2.2 `focuswindow` 与 window selectors

Hyprland dispatcher 原生提供：

```text
focuswindow
```

可以定位匹配窗口；同时还有：

- `movetoworkspace`；
- `movetoworkspacesilent`；
- `tagwindow`；
- `togglefloating`；
- directional focus 等。

### 对本规范的影响

Hyprland 很适合作为 semantic addressing 的实现后端：角色和搜索层可以直接映射到具体窗口，再由 dispatcher 聚焦或移动。

---

## 2.3 Special workspace

Hyprland 把 special workspace 明确定义为其他 WM 常说的 scratchpad：

> 可以在任意 monitor 上 toggle 的特殊 workspace。

### 与本规范的区别

传统 scratchpad 的身份通常是“窗口被藏在 special workspace”。

本规范更进一步：

> global-main 的身份属于对象本身，而不是属于某个隐藏 workspace。

因此实现可以利用 special workspace，但用户层不应该被迫理解 scratchpad 的物理位置。

---

## 2.4 Master Layout

官方文档：

https://wiki.hypr.land/Configuring/Layouts/Master-Layout/

当前 Master Layout 支持：

- master/slave；
- master orientation left/right/top/bottom/center；
- `focusmaster`；
- `swapwithmaster`；
- `mfact` 调整比例；
- per-workspace orientation。

### 对本规范的影响

Hyprland 比 niri 更容易实验：

- primary + secondary composition；
- 显式二分屏；
- resize；
- 主窗口锚点。

但本规范不要求用户记忆整个 master/slave 树；只有当前可见 composition 才应拥有空间语义。

---

# 3. Noctalia

## 3.1 Launcher / shell IPC

当前文档：

https://docs.noctalia.dev/noctalia/ipc/

Hyprland compositor integration：

https://docs.noctalia.dev/noctalia/compositor-settings/hyprland/

当前官方建议中存在：

```text
Mod+Space → launcher
Alt+Tab   → window switcher
```

以及 control center/settings 等 shell binds。

### 对本规范的影响

`Mod+Space` 是非常合适的最高频搜索入口：

- 键位大；
- 易触发；
- 已是 Noctalia launcher 的推荐入口；
- 不占用角色字母。

本规范把它从单纯 app launcher 提升成：

> **统一对象搜索：role / window / workspace / application。**

Noctalia 可以成为 UI 前端，但最终窗口动作仍由 compositor/helper 完成。

---

# 4. 哪些是现有惯例，哪些是本规范的新组合

## 已有成熟惯例

```text
Mod = compositor-level actions
数字 = workspace fast access
Tab = temporal/recent switching
T = terminal
Q = close/quit
V = floating
R = resize/size
Space = launcher/search
named workspace
window search/focus
scratchpad/special workspace
```

这些并不全属于同一个项目，但都有成熟先例。

---

## 本规范的核心新组合

### 1. Role-first

```text
Mod+B = local browser
```

不是单纯：

```text
spawn firefox
```

而是稳定的 role slot：focus if exists, otherwise create。

### 2. `Alt = global-main scope`

```text
Mod+B     local browser
Mod+Alt+B global-main browser
```

把作用域做成可组合语法。

### 3. Global Main roaming

不是把用户送去主实例所在地，而是把主实例召回当前 workspace。

### 4. `Shift = compose`

```text
Mod+B       switch/focus browser
Mod+Shift+B preserve current + show browser beside it
```

把“选择对象”和“如何呈现对象”拆成两个正交维度。

### 5. Search-first long tail

不使用 marks 给任意窗口额外命名，而是复用自然名称、标题、workspace 名搜索。

### 6. Background order is meaningless

只有当前同时可见的 pane 才有左右/上下空间语义；后台窗口内部顺序对用户不构成契约。

这一点使本规范能够同时适配 niri 的 strip 和 Hyprland 的 layout tree，而不把任一实现细节暴露给用户。

---

# 5. 当前参考结论

现阶段没有证据表明 niri、Hyprland、Noctalia 中任何一个项目已经完整提供本仓库定义的用户模型。

本草案更像把几个成熟机制重新组合成统一语法：

```text
semantic addressing
+ named workspaces
+ deterministic search
+ local/global role scope
+ temporal back
+ explicit composition
```

因此后续实现应优先验证**用户模型是否成立**，而不是追求对某个 compositor 默认配置的忠实复制。
