# Window Keybindings Specification

状态：**Draft v0.7**

本文定义窗口、工作区与搜索的用户语义。实现细节不应反过来成为用户必须记住的东西。

---

# 1. 核心原则

## 1.1 创建后可遗忘

用户创建窗口后，不应为了未来再次访问它而 mark、额外命名或记住它的位置。

窗口身份来自用户本来就知道的信息：应用名、窗口标题、role、workspace 名称。

> **Window identity ≠ window position ≠ creation order ≠ MRU distance.**

MRU 只用于多个等价候选之间的消歧。

## 1.2 Role key 只表达“我要什么”

v0.7 删除 `Global Main`、`Mod+Alt+Role` 与 role scope promotion。

Role 只保留两种策略：

```text
Contextual
→ 在当前 workspace 解析

Singleton
→ 在全局解析
```

用户只需要记住 role 本身，不需要再记 Local/Main/Global 的内部 taxonomy。

## 1.3 三种主要寻址方式

### A. 已知角色：直接 role 键

```text
Mod+B → browser
Mod+T → terminal
Mod+E → editor
Mod+A → agent / ChatGPT
Mod+N → notes / Obsidian
```

### B. 已知名字：统一搜索

```text
Mod+D
fi
Enter
```

搜索覆盖 window / application / named workspace；未来可扩展 alias。

### C. 只想回到刚才：历史

```text
Mod+Tab
```

---

# 2. Role 模型

v0.7 初始映射：

```text
browser  → Google Chrome    → contextual
terminal → Ghostty          → contextual
editor   → Zed              → contextual
agent    → ChatGPT          → singleton
notes    → Obsidian         → singleton
```

Role 表达用户意图，不要求永久绑定某个实现软件。

## 2.1 Contextual role

适用于明显依赖 workspace/project 上下文的多窗口工具：Browser、Terminal、Editor。

统一行为：

```text
Mod+Role
→ current focused workspace
→ match role window identity
→ 0: create
→ 1: focus
→ 2+: focus MRU
```

Contextual role 不关心同一应用是否只有一个主进程；候选对象是 compositor 中的 top-level windows。

### Browser

```text
Mod+B
→ 当前 workspace 的 Chrome windows
```

没有时创建新 Chrome window；已有多个时取当前 workspace MRU。

### Terminal

```text
Mod+T
→ 当前 workspace 的普通 Ghostty shell windows
```

### Editor

```text
Mod+E
→ 当前 workspace 的 Zed windows
```

## 2.2 Singleton role

适用于天然只有一个实例，或用户语义上只需要一个全局目标的工具。

统一行为：

```text
Mod+Role
→ match globally
→ 0: create
→ 1: summon + focus
→ 2+: global MRU → summon + focus
```

Singleton 不要求底层程序技术上绝对只能有一个窗口；它是用户访问 policy。

### Agent / ChatGPT

```text
Mod+A
→ globally resolve ChatGPT
→ summon-or-create
```

### Notes / Obsidian

```text
Mod+N
→ globally resolve Obsidian
→ summon-or-create
```

如果未来 Notes 真实使用转为多 workspace、多上下文，再把它改成 contextual；不预先为了理论可能性增加第二套 scope。

---

# 3. 删除 Global Main

v0.6 曾定义：

```text
Browser / Terminal / Editor
├── Local
└── Global Main
```

并通过：

```text
Mod+Role
Mod+Alt+Role
```

区分。

v0.7 完全删除这一核心模型。

原因：

1. 多实例工具本来就通常和 workspace/project 上下文绑定，contextual 已覆盖高频需求；
2. 单实例或只需要一个实例的工具直接用 singleton 即可；
3. `main browser`、`main terminal`、`main editor` 通常不是天然用户语义，而是人为指定的 identity；
4. 为 Main 额外制造 app_id、window-id state 或等待 compositor metadata，会让实现复杂度高于实际价值；
5. 如果用户真正需要的是一个跨 workspace 保持身份的具体对象，它通常有更明确的名字，例如 production SSH、logs、dashboard，而不是 “Terminal Main”。

因此：

```text
Global Main
Mod+Alt+B/T/E
runtime global-main.json
```

不再属于核心设计。

---

# 4. Semantic Alias / Scratchpad

真正需要跨 workspace 保持具体 identity 的对象，未来使用 **Semantic Alias** 或 scratchpad 模型。

例如：

```text
production SSH
logs
database console
Grafana dashboard
scratch terminal
```

这些对象的语义是具体目标，而不是 application role 的 Main。

Alias 可以通过搜索访问：

```text
Mod+D
prod
Enter
```

只有确实高频时才升级为固定直接键。

niri 原生 window labels/tags/metadata 将来非常适合成为 Alias/Scratchpad identity backend，但它不再是 v0.7 核心 role 的依赖或 blocker。

---

# 5. Terminal 与 TUI identity 隔离

`terminal` role 表达普通交互 shell，不代表任何由 terminal emulator 承载的窗口。

普通 Terminal 只匹配默认 Ghostty app_id：

```text
com.mitchellh.ghostty
```

独立 TUI application surface 使用专用 app_id：

```text
Lazygit
app_id = dev.zaviro.tui.lazygit

Yazi
app_id = dev.zaviro.tui.yazi
```

概念启动：

```text
ghostty --class=dev.zaviro.tui.lazygit -e lazygit
ghostty --class=dev.zaviro.tui.yazi -e yazi
```

如果用户在普通 Ghostty shell 中手动运行 `lazygit`：

```text
ghostty
$ lazygit
```

窗口仍然是 Terminal。Role 由窗口创建 identity 决定，不检查 foreground process。

v0.7 不再需要 `dev.zaviro.role.terminal-main` 这类 Main identity。

---

# 6. Browser 与进程模型

Browser 是 v0.7 明确记录的边界：窗口 identity 不能依赖启动命令 PID。

Chrome 可能由已有 browser instance 接收新的 `--new-window` 请求，因此：

```text
command PID ≠ new browser window identity
```

helper 创建窗口时使用 compositor observation：

```text
before = current niri window IDs
spawn command
wait until:
  matching app_id
  AND new window ID not in before
```

因此即使多个 Chrome windows 共享同一 browser process，它们仍是不同的 niri top-level windows，可以正常按 workspace 与 MRU 解析。

---

# 7. Workspace 与搜索

## 7.1 Workspace 应有语义名称

例如：

```text
main
nix-config
learning
media
```

内部 ID、显示器位置与物理顺序不是身份。

## 7.2 `Mod+1..9` 只是快速槽位

数字映射可以提供肌肉记忆，但 workspace 名称才是可恢复的语义身份。

## 7.3 `Mod+D` 是唯一主搜索入口

优先复用 Noctalia windows/application providers；workspace provider 后续按实际体验补充。

不重新引入 `Mod+Space`。

---

# 8. niri 原生窗口管理能力保留

语义寻址不替代 compositor 的空间操作系统。

原则上继续保留：

- `Mod+O` overview；
- `Mod+Q` close；
- `Mod+F` maximize column；
- `Mod+Shift+F` fullscreen；
- `Mod+R` preset width；
- `Mod+V` floating；
- `Mod+Tab` recent windows；
- 原生方向 focus / move / resize；
- workspace 切换、移动与重排；
- consume / expel 等。

---

# 9. v0.7 快捷键表

| 快捷键 | Role policy | 行为 |
|---|---|---|
| `Mod+B` | Browser contextual | current workspace；0=create，1=focus，2+=MRU |
| `Mod+T` | Terminal contextual | current workspace 普通 Ghostty；0=create，1=focus，2+=MRU |
| `Mod+E` | Editor contextual | current workspace Zed；0=create，1=focus，2+=MRU |
| `Mod+A` | Agent singleton | global summon-or-create |
| `Mod+N` | Notes singleton | global summon-or-create |
| `Mod+D` | Unified Search | Noctalia / providers |
| `Mod+Tab` | History | 保留 niri |

明确不再定义：

```text
Mod+Alt+B
Mod+Alt+T
Mod+Alt+E
Mod+Alt+A
Mod+Alt+N
```

`Alt` 仍可被 compositor 或未来其他功能使用，但不再承担 role scope 语义。

---

# 10. Helper 实现边界

正式 CLI：

```text
window-keybindings contextual ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings singleton ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings inspect
```

兼容 alias：

```text
local  → contextual
single → singleton
```

删除：

```text
global
global-state
state
forget
reset
```

因此 helper 不保存任何窗口 identity runtime state。

仍保留 session-local `flock` lock，仅用于防止快速连续触发产生重复窗口；该 lock 不是窗口 identity state。

## 10.1 contextual

```text
query current focused workspace
→ exact/narrow app_id match
→ 0: spawn and observe new window ID
→ 1: focus
→ 2+: MRU
```

## 10.2 singleton

```text
query globally
→ 0: spawn and observe new window ID
→ 1: summon/focus
→ 2+: global MRU → summon/focus
```

## 10.3 identity 原则

核心 role 优先使用窗口自身已有 `app_id`；v0.7 不为 role 人工维护 window-id identity。

niri labels 将来只在真实需要跨 workspace 持久具体 identity 的 alias/scratchpad 上引入。

---

# 11. Future / Experimental

## 11.1 Semantic Alias / Scratchpad

优先解决具体稳定对象，而不是恢复通用 Global Main。

## 11.2 Directional Activation

未来可实验：

```text
Mod+←+B
→ 保留当前窗口
→ 激活 contextual Browser
→ Browser 最终位于左侧
```

对于 singleton：

```text
Mod+←+A
→ summon Agent
→ 与当前窗口形成目标布局
```

不重新引入 `Alt = Global`。

## 11.3 Workspace 自动命名

属于更高层 policy，不阻塞 v0.7。

---

# 12. 评估新快捷键的准则

新增能力前依次问：

1. 用户是否已经知道目标是什么？
2. 是否能直接通过 role 或名字表达？
3. 是否在制造第二套位置、Main 或 mark 记忆？
4. 是否可以通过统一搜索解决？
5. 是否足够高频，值得固定快捷键？
6. 如果目标依赖当前项目，它是否应为 contextual？
7. 如果用户只需要一个目标，它是否应为 singleton？
8. 若需要跨 workspace 保持具体对象，是否应该建模成有名字的 Alias/Scratchpad，而不是恢复 Global Main？
9. 新 identity 能否由窗口/compositor 自身表达？
10. 是否明显降低了认知或操作成本？

如果答案不明确，就不要加入核心规范。
