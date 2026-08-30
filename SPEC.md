# Window Keybindings Specification

状态：**Draft v0.6**

本文定义窗口、工作区与搜索的用户语义。实现可以由 niri IPC、Hyprland dispatcher、Noctalia provider 或独立 helper 完成；实现细节不应反过来成为用户必须记住的东西。

---

# 1. 核心原则

## 1.1 创建后可遗忘

用户创建窗口后，不应为了未来再次访问它而 mark、额外命名或记住它的位置。

窗口的身份来自用户本来就知道的信息：应用名、窗口标题、role、workspace 名称。

> **Window identity ≠ window position ≠ creation order ≠ MRU distance.**

MRU 可以用于多个等价候选之间的消歧，但不成为窗口身份。

---

## 1.2 Role key 优先表达“我要这个东西”

快捷键首先服务于访问频率和可记忆性，而不是为了形式统一增加 modifier。

因此 v0.6 的规则是：

```text
Role 只有一个全局语义目标
→ Mod+Role 直接访问它

Role 同时存在 Local + Global 两种 scope
→ Mod+Role      = Local
→ Mod+Alt+Role  = Global Main
```

`Alt` 不再表示“所有全局对象都必须使用 Alt”，而只承担：

> **当同一个 role 同时存在 Local / Global 两种作用域时，选择 Global scope。**

没有 scope 歧义时，不增加 Alt。

---

## 1.3 三种主要寻址方式

### A. 已知角色：直接 role 键

```text
Mod+B → browser
Mod+T → terminal
Mod+E → editor
Mod+A → agent / ChatGPT
Mod+N → notes / Obsidian
```

用户已经知道目标是什么时，不应再通过方向、Alt-Tab 次数或搜索位置寻找。

### B. 已知名字：统一搜索

```text
Mod+D
fi
Enter
```

搜索应覆盖：

- 当前与其他 workspace 的运行中窗口；
- application；
- named workspace；
- 后续可扩展 role / Global Main / alias 对象。

通常输入前 2–3 个字符即可选择。

### C. 只想回到刚才：历史

```text
Mod+Tab
```

MRU 只回答“刚才那个是什么”，不承担寻找任意已知目标的职责。

---

# 2. 搜索模型

## 2.1 `Mod+D` 是唯一主搜索入口

v0.2 起删除 `Mod+Space`。

原因：

- `Mod+Space` 与许多应用、输入法、桌面习惯容易冲突；
- 同时保留 `Mod+Space` 与 `Mod+D` 会制造两个高度重叠的搜索入口；
- niri 默认已经使用 `Mod+D` 表达 Run Application，扩展成 Destination / Discover 搜索更自然。

---

## 2.2 优先复用 Noctalia，而不是另造 launcher

Noctalia 已提供 application launcher 与 windows provider。实验阶段优先组合成统一搜索：

```text
Chrome — GitHub           [window]
Chrome — NixOS docs       [window]
Google Chrome             [application]
window-keybindings        [workspace]
```

选择 window → 跳转现有窗口。

选择 application → 启动应用/新窗口，具体行为由应用能力决定。

如果 Noctalia 原生 ranking / provider 组合不足，再写薄 provider/plugin，而不是另造完整 launcher UI。

---

## 2.3 两字母快捷序列暂不进入核心规范

例如：

```text
Mod → F → I → Firefox
```

这种序列需要 leader/submap/chord 系统，并不属于 niri 普通 `modifier + key` 绑定模型。

长尾应用暂时统一使用：

```text
Mod+D → 输入 2–3 字母 → Enter
```

只有真正达到高频、稳定且值得 O(1) 访问的对象，才升级成固定 role 或 alias。

---

# 3. Role 模型

Role 表达用户意图，不是窗口的位置，也不要求永久绑定某个实现软件。

v0.6 初始映射：

```text
browser  → Google Chrome
terminal → Ghostty（仅普通 shell 窗口身份）
editor   → Zed
agent    → ChatGPT
notes    → Obsidian
```

未来可以替换实现应用而不改变快捷键的用户语义。

## 3.1 两种 scope policy

v0.6 将 role 明确分成两种：

```text
Dual Scope
Terminal / Browser / Editor
├── Global Main        # 0..1，全局唯一
└── Local Instances    # 0..N，分布于各 workspace

Global Singleton
Agent / Notes
└── Global Singleton   # 用户语义上只有一个直接目标
```

### Dual Scope

适用于既需要“当前 workspace 的普通实例”，又需要“全局随叫随到主实例”的工具。

绑定规则：

```text
Mod+Role      → Local
Mod+Alt+Role  → Global Main
```

### Global Singleton

适用于天然只能单实例，或用户明确只把它当一个全局实例使用的工具。

绑定规则：

```text
Mod+Role → Global Singleton
```

不额外定义 `Mod+Alt+Role`，因为没有作用域需要消歧。

“Global Singleton”描述的是快捷键/用户语义，不强制要求底层进程技术上只能启动一次。例如 Obsidian 即使未来出现多个窗口，Notes role 仍可按全局候选策略解析；如果真实使用逐渐需要多个 scope，再升级为 Dual Scope。

---

## 3.2 Local role：focus-or-create

v0.6 的 Local 绑定：

```text
Mod+B → 当前 workspace browser
Mod+T → 当前 workspace terminal
Mod+E → 当前 workspace editor
```

以 `Mod+T` 为例：

1. 只在当前 workspace 查找 terminal 的 **Local Instances**；
2. 始终排除 terminal 的 Global Main，即使它物理上也位于当前 workspace；
3. 没有 Local Instance → 创建一个新的 local terminal；
4. 恰好一个 → focus；
5. 两个及以上 → focus **MRU Local Instance**。

Browser 与 Editor 同理。

```text
Mod+Role
→ current workspace
→ match local role identity
→ exclude Global Main
→ 0: create local
→ 1: focus
→ 2+: focus MRU
```

niri 官方默认 `Mod+T` 是 spawn terminal；规范保留 `T = Terminal` 的成熟语义，但把动作升级为 local focus-or-create。

---

## 3.3 Terminal 与 TUI application 的身份隔离

`terminal` role 表达“普通交互 shell 终端”，而不是“任何由终端模拟器承载的窗口”。

> **普通 Terminal 只匹配默认 Ghostty app_id；以独立 application / role 身份启动的 TUI 必须使用独立 app_id，并从 Terminal role 中天然排除。**

概念示例：

```text
普通 Ghostty shell
app_id = com.mitchellh.ghostty
→ terminal local role

Terminal Global Main
app_id = dev.zaviro.role.terminal-main
→ terminal Global Main

Lazygit application surface
app_id = dev.zaviro.tui.lazygit
→ lazygit identity
→ 不属于 terminal role

Yazi application surface
app_id = dev.zaviro.tui.yazi
→ yazi identity
→ 不属于 terminal role
```

可以继续全部使用 Ghostty renderer：

```text
ghostty

ghostty --class=dev.zaviro.role.terminal-main
ghostty --class=dev.zaviro.tui.lazygit -e lazygit
ghostty --class=dev.zaviro.tui.yazi -e yazi
```

### 身份由启动方式决定，而不是前台进程决定

如果用户从普通 shell 手工运行：

```text
ghostty
$ lazygit
```

该窗口仍然是 Terminal。helper 不检查 foreground process，也不因为临时进入某个 TUI 而改变窗口 role。

未来若给 TUI 增加 direct binding / alias，应创建或聚焦具有专用 app_id 的 TUI surface。

---

## 3.4 Dual-Scope Global Main

v0.6 绑定：

```text
Mod+Alt+B → global-main browser
Mod+Alt+T → global-main terminal
Mod+Alt+E → global-main editor
```

`Alt` 在这里的意义仅是：

> **同一 role 已经有 Local 语义，因此用 Alt 选择 Global Main。**

每个 Dual-Scope role 在整个会话中最多存在一个 Global Main：

```text
browser  → 0..1 global-main browser
terminal → 0..1 global-main terminal
editor   → 0..1 global-main editor
```

Global Main **语义上不属于任何 workspace**。当前物理位置只是 compositor 状态，不构成身份。

### 激活 policy：Summon

Global Main 位于其他 workspace 时，移动对象而不是移动用户：

```text
当前 workspace ← Global Main
focus Global Main
```

完整行为：

1. 已存在且在当前 workspace → focus；
2. 已存在但在其他 workspace → move 到当前 workspace，再 focus；
3. 不存在 → 创建对应 Global Main identity，再 focus。

```text
Mod+Alt+Role
→ resolve Global Main identity
→ absent: create / establish identity
→ elsewhere: summon to current workspace
→ focus
```

不做原 workspace 的占位或恢复逻辑。

---

## 3.5 Global Singleton

v0.6 正式启用：

```text
Mod+A → Agent / ChatGPT
Mod+N → Notes / Obsidian
```

不定义：

```text
Mod+Alt+A
Mod+Alt+N
```

因为 Agent / Notes 当前没有 Local 与 Global 两套 scope。

### Agent / ChatGPT

ChatGPT 当前按天然单实例应用处理：

```text
Mod+A
→ find ChatGPT globally
→ exists elsewhere: summon
→ exists here: focus
→ absent: spawn
```

使用天然唯一 app_id，不保存额外身份状态。

### Notes / Obsidian

Obsidian 当前按用户策略上的 global singleton 处理：

```text
Mod+N
→ find Notes/Obsidian globally
→ exists elsewhere: summon
→ exists here: focus
→ absent: spawn
```

如果意外存在多个匹配窗口，v0.6 取全局 MRU 候选；这只是 rare-case 消歧，不意味着 MRU 成为身份。

采用 `Mod+N` 意味着实现接入时需要释放当前可能占用该键的 desktop-shell 功能。对现有 Noctalia Control Center 绑定应另行迁移或通过 Noctalia UI/其他入口访问；不因为旧绑定存在而牺牲高频 Notes role 的直接入口。

---

# 4. Workspace 模型

## 4.1 Workspace 应有名字

长期 workspace 应具有语义名称，例如：

```text
main
window-keybindings
learning
media
```

内部 ID、显示器位置和物理顺序都不是身份。

## 4.2 `Mod+1..9` 是快捷槽位，不是 workspace 身份

例如：

```text
1 → main
2 → window-keybindings
3 → learning
```

忘记数字时仍然可以：

```text
Mod+D
win
Enter
```

数字提供肌肉记忆，名称提供可恢复的语义记忆。

具体 `1..9` 映射暂不阻塞 v0.6 实现。

## 4.3 自动命名属于 policy 层

niri 原生负责 named workspace、按名称 focus、运行时设置 workspace name。

“根据项目目录/第一个重要窗口自动给 workspace 命名”属于更高层 policy，可由 event-stream helper 实现，不应写死到 compositor 身份模型中。

v0.6 不实现自动命名。

---

# 5. niri 原生窗口管理能力全部保留

语义寻址是新增层，不替代 niri 的空间操作系统。

以下 niri 默认/成熟操作原则上保留：

- `Mod+O` overview；
- `Mod+Q` close；
- `Mod+F` maximize column；
- `Mod+Shift+F` fullscreen；
- `Mod+R` preset width；
- `Mod+V` floating；
- `Mod+Tab` recent windows；
- 方向 focus；
- `Mod+Ctrl+方向` 等窗口/列移动；
- workspace 切换、移动与重排；
- consume / expel；
- window height / column width 调整；
- center / expand 等。

即使高频场景很少使用某些键，也没有必要删掉。它们保留 compositor 的完整原生能力与可靠 fallback。

---

# 6. 删除 / 修正的早期设计

## 6.1 删除 `Mod+Space`

与 `Mod+D` 重复且冲突面更大。

## 6.2 删除 `Mod+Shift+Role = compose`

布局组合属于布局层，不应绑死到 role 层。未来优先采用方向语义。

## 6.3 不限制 `Mod+方向` 只在可见窗口内

niri 原生方向导航、滚动 strip、窗口重排全部保留。

## 6.4 v0.6 修正：`Alt` 不再是“Global 的固定前缀”

v0.5 曾将 `Mod+Alt+A` 用于天然 global-only 的 Agent。v0.6 删除这一要求。

原因：

- 没有 Local Agent，就没有 scope 歧义；
- 额外 Alt 只增加操作成本；
- Role key 应优先表达“我要这个对象”；
- modifier 应只在真实存在歧义时出现。

---

# 7. v0.6 快捷键表

## 7.1 语义寻址

| 快捷键 | Role / scope | v0.6 行为 |
|---|---|---|
| `Mod+D` | Unified Search | Noctalia window / application；workspace provider 后续接入 |
| `Mod+B` | Browser Local | 排除 Global Main；0=create，1=focus，2+=MRU |
| `Mod+T` | Terminal Local | 仅普通 Ghostty identity；0=create，1=focus，2+=MRU |
| `Mod+E` | Editor Local / Zed | 排除 Global Main；0=create，1=focus，2+=MRU |
| `Mod+Alt+B` | Browser Global Main | summon-or-create |
| `Mod+Alt+T` | Terminal Global Main | 优先专用 app_id；summon-or-create |
| `Mod+Alt+E` | Editor Global Main | summon-or-create |
| `Mod+A` | Agent Global Singleton / ChatGPT | global MRU/single match；summon-or-create |
| `Mod+N` | Notes Global Singleton / Obsidian | global MRU/single match；summon-or-create |
| `Mod+Tab` | previous/recent window | 保留 niri |

明确不绑定：

```text
Mod+Alt+A
Mod+Alt+N
```

## 7.2 Workspace

| 快捷键 | 语义 |
|---|---|
| `Mod+1..9` | named workspace 的快速槽位；映射待实测 |
| niri 原生 workspace 键 | 保留 |

## 7.3 原生窗口管理

`Mod+O/Q/F/R/V/Shift+F` 以及 niri 默认方向、移动、重排、resize、consume/expel 等全部保留。

---

# 8. Future / Experimental

本节记录未来值得实测的能力。它们不是当前核心规范，也不阻塞 v0.6 实现。

## 8.1 Semantic Alias

允许用户把任意稳定、高频目标注册为直接语义地址，并分配 `Mod+字母` 一类 O(1) 入口。

Alias 与 Role 共用：

```text
目标已有 → focus / activate
目标不存在 → create
```

Alias 必须保持少量、可选，不能退化成需要维护大量 mark 的第二套命名系统。

---

## 8.2 Directional Activation

未来可能把“保留当前窗口 + 激活目标 + 排列”合成一次操作。

方向箭头描述**目标窗口的最终位置**：

```text
Mod+←+B
→ local Browser 放左边

Mod+Alt+←+B
→ Global Main Browser summon 后放左边
```

v0.6 的 modifier 规则同样适用于方向组合：

```text
Dual Scope role:
  Mod+方向+Role       → Local target
  Mod+Alt+方向+Role   → Global Main target

Global Singleton role:
  Mod+方向+Role       → Singleton target
  不增加 Alt
```

所以 Agent 若未来支持方向组合，应是：

```text
Mod+方向+A
```

而不是 `Mod+Alt+方向+A`。

已有多 pane 布局、默认比例、focus policy、真实 chord 实现等仍待实测。

---

# 9. v0.6 实现边界

## 9.1 role 行为由薄 helper 完成

```text
key bind
  ↓
semantic helper
  ↓
query niri windows/workspaces
  ↓
apply role scope policy
```

### Dual Scope / Local

```text
query current workspace
→ match Local identity
→ exclude Global Main
→ 0: spawn
→ 1: focus
→ 2+: MRU
```

### Dual Scope / Global Main

```text
resolve Global Main identity
→ absent: spawn corresponding identity
→ elsewhere: summon to current workspace
→ focus
```

### Global Singleton

```text
query matching windows globally
→ 0: spawn
→ 1: summon/focus
→ 2+: global MRU → summon/focus
```

Global Singleton 不需要额外 Local/Global identity 层。

---

## 9.2 Identity / 状态后端的强制优先级

实现必须按以下顺序选择身份来源：

1. **窗口自身 `app_id` 能表达 → 绝不用外部状态。**
2. **单实例应用如 ChatGPT → 直接使用天然唯一的 `app_id`。**
3. **只有无法给不同实例赋不同 identity 的 GUI 应用 → 才临时使用 runtime state。**
4. **niri 原生 window labels/tags/metadata 正式合并并进入实际使用版本后 → 将剩余 runtime-state role 迁移为 niri-native identity，并删除对应外部状态。**

优先结构：

```text
Window identity
├── dedicated app_id          # 首选；zero external state
├── natural singleton app_id  # 单实例；zero external state
├── niri-native label/tag     # 正式可用后优先 compositor metadata
└── runtime window-id state   # 仅兼容 fallback
```

### app_id-backed Global Main

```text
Local Terminal
app_id = com.mitchellh.ghostty

Terminal Global Main
app_id = dev.zaviro.role.terminal-main
```

因此：

```text
Mod+T
→ match ^com[.]mitchellh[.]ghostty$

Mod+Alt+T
→ match ^dev[.]zaviro[.]role[.]terminal-main$
```

Global Main 身份直接存在于窗口自身；helper 不保存 window id。

### natural / policy singleton identity

ChatGPT：天然 singleton，直接匹配 app_id。

Obsidian：当前按 policy singleton 使用；如果底层出现多个同 app_id 窗口，helper 只在候选中做 global MRU 消歧，不为了这一 rare case 引入外部 identity 状态。

### runtime-state fallback

只有应用无法为 Local 与 Global Main 暴露不同 window identity 时，才允许登记 session-local window id：

```text
$XDG_RUNTIME_DIR/window-keybindings/global-main.json
```

约束：

- 只在当前登录会话有效；
- 每次读取必须对照 niri 当前 windows 校验 window id；
- Local Instances 永远不登记；
- fallback 必须显式可见，不能悄悄成为默认行为；
- niri-native metadata 可用后删除对应 fallback。

当前 helper 把默认 `global` 定义为 app_id-backed backend，把外部状态单独暴露为 `global-state` compatibility backend。

---

## 9.3 v0.6 role 映射先静态声明

第一阶段不做动态 role 注册 UI，不做常驻 daemon。

概念映射：

```text
browser:
  scope = dual
  local.match = Google Chrome local app_id
  local.spawn = google-chrome
  global.prefer = dedicated app_id
  global.fallback = runtime state only if necessary

terminal:
  scope = dual
  local.match = com.mitchellh.ghostty
  local.spawn = ghostty
  global.match = dev.zaviro.role.terminal-main
  global.spawn = ghostty --class=dev.zaviro.role.terminal-main

editor:
  scope = dual
  local.match = Zed local app_id
  local.spawn = zed
  global.prefer = dedicated app_id
  global.fallback = runtime state only if necessary

agent:
  scope = global-singleton
  match = ChatGPT natural app_id
  spawn = ChatGPT launcher command
  key = Mod+A

notes:
  scope = global-singleton
  match = Obsidian app_id
  spawn = obsidian
  key = Mod+N
```

对于独立 TUI 继续使用专用 Ghostty app_id，例如：

```text
lazygit:
  match = dev.zaviro.tui.lazygit
  spawn = ghostty --class=dev.zaviro.tui.lazygit -e lazygit

yazi:
  match = dev.zaviro.tui.yazi
  spawn = ghostty --class=dev.zaviro.tui.yazi -e yazi
```

实际 app_id 与启动命令以本机 niri 查询结果和 NixOS 安装方式为准。

---

## 9.4 Helper CLI

正式接口：

```text
window-keybindings local ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings global ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings global-state ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings singleton ROLE APP_ID_REGEX -- COMMAND [ARG...]
```

- `local`：Dual-Scope Local；
- `global`：Dual-Scope Global Main，app_id-backed 首选；
- `global-state`：无法区分 identity 时的显式兼容 fallback；
- `singleton`：Global Singleton；全局查找、summon-or-create，不保存额外身份状态。

旧命令名 `single` 可作为兼容 alias 保留，但文档与新配置统一使用 `singleton`。

---

## 9.5 搜索优先实验 Noctalia

第一阶段不开发新 launcher。

先验证 windows provider、application/window ranking、workspace provider 与 2–3 字符后 Enter 的实际体验。

---

# 10. v0.6 之后仍待实测的问题

这些问题不阻塞当前实现：

1. Browser / Terminal / Editor 的 Global Main 是否都实际高频；低频项可删除。
2. 多 Local 使用 MRU 是否符合直觉。
3. Summon 是否持续比 Jump 自然。
4. Global Main 被 summon 后是否完全不需要原 workspace 占位/恢复。
5. 专用 TUI app_id 使用体验是否稳定。
6. Chrome 是否能稳定为 Global Main 暴露独立 app_id；不能则暂用 runtime-state fallback。
7. Zed 是否能稳定为 Global Main 暴露独立 app_id；不能则暂用 runtime-state fallback。
8. ChatGPT `Mod+A` 是否形成稳定高频肌肉记忆。
9. Obsidian `Mod+N` 是否适合作为长期 Notes singleton；如果未来大量使用多窗口/多 vault，再重新评估 scope policy。
10. `Mod+N` 原 Noctalia Control Center 绑定应迁移到哪个入口。
11. Noctalia window/application ranking 是否足够。
12. named workspace 是否需要自动命名。
13. workspace slot `1..9` 应固定还是动态映射。
14. niri 原生 window labels/tags/metadata 何时进入可实际使用版本；进入后迁移剩余 runtime-state backend。
15. Semantic Alias 是否会保持少量高频对象。
16. Directional Activation 在已有多 pane composition 中如何表现。

---

# 11. 评估新快捷键的准则

新增任何键位前依次问：

1. 用户是否已经知道目标是什么？
2. 是否在制造第二套名字或位置记忆？
3. 是否与已有成熟默认键冲突？
4. 是否可以通过统一搜索解决，而不增加固定键？
5. 这个键是否真的足够高频，值得进入长期肌肉记忆？
6. modifier 是否只用于真实存在的歧义，而不是为了形式统一？
7. 如果换掉 niri / Hyprland，这个快捷键的用户意义能否保持？
8. 新功能是否仍满足“创建后可遗忘”？
9. 新增 identity 是否能够由窗口/compositor 自身表达，而不是无必要地制造外部状态？
10. 对 global singleton 来说，是否真的需要额外 scope modifier？默认答案应是“不需要”。

如果不能明显降低认知或操作成本，就不应加入核心规范。
