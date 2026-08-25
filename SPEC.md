# Window Keybindings Specification

状态：**Draft v0.5**

本文定义窗口、工作区与搜索的用户语义。实现可以由 niri IPC、Hyprland dispatcher、Noctalia provider 或独立 helper 完成；实现细节不应反过来成为用户必须记住的东西。

---

# 1. 核心原则

## 1.1 创建后可遗忘

用户创建窗口后，不应为了未来再次访问它而 mark、额外命名或记住它的位置。

窗口的身份来自用户本来就知道的信息：应用名、窗口标题、role、workspace 名称。

> **Window identity ≠ window position ≠ creation order ≠ MRU distance.**

---

## 1.2 三种主要寻址方式

当前核心只保留三个高层入口。

### A. 已知角色：直接 role 键

```text
Mod+B → browser
Mod+T → terminal
Mod+E → editor
Mod+Alt+A → agent global-main
```

用户已经知道“我要浏览器 / 终端 / 编辑器 / Agent”时，不应再通过方向、Alt-Tab 次数或搜索位置寻找。

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
- 后续可扩展 role / global-main / alias 对象。

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
- niri 默认已经使用 `Mod+D` 表达 Run Application，扩展成 Destination / Discover 搜索比重新引入第二入口更自然。

---

## 2.2 优先复用 Noctalia，而不是另造 launcher

Noctalia 已提供 application launcher 与 windows provider。实验阶段优先把它组合成统一搜索：

```text
Chrome — GitHub           [window]
Chrome — NixOS docs       [window]
Google Chrome             [application]
window-keybindings        [workspace]
```

选择 window → 跳转现有窗口。

选择 application → 启动应用/新窗口，具体行为由应用能力决定。

因此搜索器不必替用户猜测“你要哪一个 Chrome”；匹配结果本身表达目标对象。

如果 Noctalia 原生 ranking / provider 组合不足，再写一个薄 provider/plugin，而不是另造完整 launcher UI。

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

v0.5 的初始实现映射为：

```text
browser  → Google Chrome
terminal → Ghostty
editor   → Zed
agent    → ChatGPT
```

未来可以替换实现应用而不改变快捷键的用户语义。

普通 role 可以同时具有两种作用域的实例语义：

```text
Terminal / Browser / Editor
├── Global Main        # 0..1，全局唯一
└── Local Instances    # 0..N，分布于各 workspace
```

**Global Main 与 Local Instance 是不同身份。** Global Main 即使物理上位于当前 workspace，也不因此成为该 workspace 的 Local Instance。

Agent 是 v0.5 的特殊 global-only role：ChatGPT 当前只使用单实例，因此不定义 Agent Local Instance。

---

## 3.1 Local role

### v0.5 绑定

```text
Mod+B → 当前 workspace browser
Mod+T → 当前 workspace terminal
Mod+E → 当前 workspace editor
```

Agent 不提供 `Mod+A` local binding。

### 规范语义：local focus-or-create

以 `Mod+T` 为例：

1. 只在当前 workspace 查找 terminal 的 **Local Instances**；
2. 查找时始终排除 terminal 的 Global Main，即使 Global Main 此刻也位于当前 workspace；
3. 没有 Local Instance → 创建一个新的 local terminal；
4. 恰好一个 Local Instance → focus；
5. 两个及以上 Local Instances → focus **MRU Local Instance**。

Browser 与 Editor 同理。

MRU 只作为“多个已经符合 role + workspace 条件的候选之间的消歧策略”，不成为窗口身份本身。

因此：

```text
Mod+Role
→ current workspace
→ match role
→ exclude Global Main
→ 0: create local
→ 1: focus
→ 2+: focus MRU
```

niri 官方默认的 `Mod+T` 是 `spawn terminal`，不是 focus-or-create。规范保留 `T = Terminal` 的成熟语义，但把动作升级为 local focus-or-create。

---

## 3.2 Global-main role

### v0.5 绑定

```text
Mod+Alt+B → global-main browser
Mod+Alt+T → global-main terminal
Mod+Alt+E → global-main editor
Mod+Alt+A → global-main agent
```

`Alt` 统一表示：

> 从 workspace-local 作用域提升到该 role 的全局唯一主实例。

### 身份与唯一性

每个 role 在整个会话中最多存在一个 Global Main：

```text
browser  → 0..1 global-main browser
terminal → 0..1 global-main terminal
editor   → 0..1 global-main editor
agent    → 0..1 global-main agent
```

Global Main **语义上不属于任何 workspace**。它当前出现在哪个 workspace 只是 compositor 的物理放置状态，不构成其身份，也不改变其 Global Main 属性。

因此：

- Global Main 可以物理上出现在任意 workspace；
- workspace 切换、移动窗口都不改变 Global Main 身份；
- local role 查找始终排除 Global Main；
- `Mod+Alt+Role` 无论 Global Main 当前在哪，都指向同一个全局唯一实例。

### v0.5 激活 policy：Summon

Global Main 位于其他 workspace 时，**移动对象，而不是移动用户**：

```text
当前 workspace ← Global Main
focus Global Main
```

完整行为：

1. Global Main 已存在且位于当前 workspace → focus；
2. Global Main 已存在但位于其他 workspace → move 到当前 workspace，再 focus；
3. Global Main 不存在 → 创建新的对应 role 实例，登记为 Global Main，再 focus。

因此：

```text
Mod+Alt+Role
→ resolve Global Main
→ absent: create + register
→ elsewhere: summon to current workspace
→ focus
```

v0.5 不做原 workspace 的占位或恢复逻辑。Global Main 本来就没有 workspace 语义所有权，被 summon 后原 workspace 直接失去该物理窗口即可。

---

## 3.3 Agent：global-only single-instance role

```text
A → Agent
implementation → ChatGPT
binding → Mod+Alt+A
```

ChatGPT 当前按单实例应用处理，因此 Agent 不建立 Local / Global 两套实例：

- 已存在匹配的 ChatGPT 窗口 → 该窗口天然视为 Agent Global Main；
- 位于其他 workspace → summon 到当前 workspace；
- 不存在 → 启动 ChatGPT，出现的窗口即为 Agent Global Main；
- 不绑定 `Mod+A`。

这使 Agent 与 Browser / Terminal / Editor 在 role 层同级，但实例策略更简单。

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

---

## 4.2 `Mod+1..9` 是快捷槽位，不是 workspace 身份

例如：

```text
1 → main
2 → window-keybindings
3 → learning
```

如果忘记数字映射，仍然可以：

```text
Mod+D
win
Enter
```

进入 `window-keybindings`。

数字提供肌肉记忆，名称提供可恢复的语义记忆。

具体 `1..9` 映射暂不阻塞 v0.5 实现。

---

## 4.3 自动命名属于 policy 层

niri 原生负责 named workspace、按名称 focus、运行时设置 workspace name。

“根据项目目录/第一个重要窗口自动给 workspace 命名”属于更高层 policy，可由 event-stream helper 实现，不应写死到 compositor 身份模型中。

v0.5 不实现自动命名。

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

# 6. 删除的早期设计

## 6.1 删除 `Mod+Space`

与 `Mod+D` 重复且冲突面更大。

## 6.2 删除 `Mod+Shift+Role = compose`

旧设计：

```text
Mod+Shift+B → 保留当前窗口并把 Browser 放旁边
```

删除原因：

- `Shift = compose` 不够直觉；
- 会与 niri 已有大量 Shift 结构操作混淆；
- 分屏/组合属于布局层，不应绑死到 role 层。

未来的布局组合如果实现，优先采用更直接的**方向语义**，见第 8 节。

## 6.3 不限制 `Mod+方向` 只在可见窗口内

niri 原生方向导航、滚动 strip、窗口重排全部保留。语义搜索只是减少其作为“找后台窗口”工具的必要性，不应破坏原始能力。

---

# 7. v0.5 快捷键表

## 7.1 语义寻址

| 快捷键 | 语义 | v0.5 行为 |
|---|---|---|
| `Mod+D` | Noctalia 统一搜索 | window / application；workspace provider 后续接入 |
| `Mod+B` | local browser | 排除 Global Main；0=create，1=focus，2+=MRU |
| `Mod+T` | local terminal | 排除 Global Main；0=create，1=focus，2+=MRU |
| `Mod+E` | local editor / Zed | 排除 Global Main；0=create，1=focus，2+=MRU |
| `Mod+Alt+B` | global-main browser | summon-or-create |
| `Mod+Alt+T` | global-main terminal | summon-or-create |
| `Mod+Alt+E` | global-main editor / Zed | summon-or-create |
| `Mod+Alt+A` | global-main agent / ChatGPT | single-instance summon-or-create |
| `Mod+A` | Agent local | **不绑定** |
| `Mod+Tab` | previous/recent window | 保留 niri |

## 7.2 Workspace

| 快捷键 | 语义 |
|---|---|
| `Mod+1..9` | named workspace 的快速槽位；映射待实测 |
| niri 原生 workspace 键 | 保留 |

## 7.3 原生窗口管理

`Mod+O/Q/F/R/V/Shift+F` 以及 niri 默认的方向、移动、重排、resize、consume/expel 等全部保留。

---

# 8. Future / Experimental：可选扩展层

本节记录未来值得实测的能力。它们**不是当前核心规范，也不阻塞 v0.5 实现**。

## 8.1 Semantic Alias：用户自定义直接地址

### 动机

不是所有稳定高频对象都适合抽象成 `browser`、`terminal`、`editor`、`agent` 这种通用 role。

未来可以允许用户把任意稳定目标注册为 **Semantic Alias**，并自行分配一个 `Mod+字母` 形式的直接入口，例如：

```text
Mod+M → music
Mod+G → 固定 GitHub / browser profile
Mod+P → 某个长期项目对象
```

这里只定义语义，不规定这些示例必须存在。

### Alias 与 Role 的关系

它们共享同一寻址模型：

```text
目标已有 → focus / activate
目标不存在 → create
```

差异在于：

- **Role** 是通用意图类别，例如 browser、terminal、editor、agent；
- **Alias** 是用户为某个真实高频对象创建的自定义直接地址。

### 约束

- Alias 必须是可选的；
- 不要求用户给所有窗口命名；
- 只有实际高频对象才值得升级为 alias；
- 长尾对象仍然走 `Mod+D` 搜索；
- Alias 不应退化成需要维护大量 mark 的第二套命名系统。

---

## 8.2 Directional Activation：一次完成“保留 + 激活 + 排列”

### 动机

未来可能需要一个比“先切换窗口，再手动整理布局”更直接的动作：

> 保留当前窗口，同时启动/激活目标，并把两者立即排列成用户想要的可见组合。

概念示例：

```text
Mod + ← + B
```

表示：保留当前窗口，激活 local browser，并组成左右布局。

### 当前首选方向规则

**箭头描述目标窗口的最终位置。**

因此：

```text
← Browser
→ [ Browser ][ Current ]

→ Browser
→ [ Current ][ Browser ]

↑ Terminal
→ Terminal 在 Current 上方

↓ Terminal
→ Terminal 在 Current 下方
```

方向直接修饰“我要加入的目标”：

```text
← Browser = Browser 放左边
```

### 与现有 role / global scope 的组合

理想语义可以保持正交：

```text
Mod+B            → local Browser
Mod+Alt+B        → global-main Browser
Mod+←+B          → local Browser 放左边并保留 Current
Mod+Alt+←+B      → summon global-main Browser 并放左边
```

也就是说：

```text
Alt         → Global Main
方向         → 目标最终位置
B/T/E/Alias → 目标对象
```

Agent 当前是 global-only，因此若未来支持方向组合，只考虑 `Mod+Alt+方向+A`，不定义 local `Mod+方向+A`。

### 尚未决定

以下问题必须实际体验后再定：

1. 目标已经在当前屏幕可见时，是只 focus、重排，还是保持原布局？
2. 目标在当前 workspace 但位于屏幕外时，是否移动其 compositor 内部位置？
3. 当前已经是两窗/三窗布局时，再执行方向激活应该新增 pane、替换某个 pane，还是重新形成二分？
4. 默认比例是 `50/50`、`60/40`，还是继承当前布局？
5. 激活后是否始终 focus target？
6. 上下分割在 niri 的列模型中是否足够自然？
7. 真实物理输入应使用 chord、leader、submap、mode 还是 helper 捕获？
8. Alias 是否也允许完全相同的方向组合语法？当前倾向是允许。

在这些问题没有实测前，Directional Activation 只作为 Future / Experimental 语义保留。

---

# 9. v0.5 实现边界

## 9.1 role 行为由薄 helper 完成

niri 默认 `spawn` 不会替我们做 focus-or-create。

```text
key bind
  ↓
semantic helper
  ↓
query niri windows/workspaces
  ↓
apply role policy
```

Local role：

```text
query current workspace windows
→ match role
→ exclude role Global Main
→ 0: spawn
→ 1: focus
→ 2+: choose greatest focus_timestamp / MRU
```

Global Main：

```text
resolve registered Global Main
→ absent: spawn new instance + register
→ elsewhere: move-window-to-workspace current
→ focus-window
```

只为真正需要身份区分的 Global Main 保存最小运行时状态。Local Instances 不登记、不持久化。

建议状态放在 `$XDG_RUNTIME_DIR/window-keybindings/`，只在当前登录会话有效，并在每次使用时对照 niri 当前窗口列表校验失效 window id。

Agent / ChatGPT 因单实例不需要额外区分 Local 与 Global：任何现有匹配窗口都可以直接作为 Agent Global Main。

---

## 9.2 v0.5 role 映射先静态声明

第一阶段不做动态 role 注册系统，不做 UI，不做常驻 daemon。

概念上只需要类似：

```text
browser:
  match = Google Chrome app_id
  spawn = google-chrome

terminal:
  match = Ghostty app_id
  spawn = ghostty

editor:
  match = Zed app_id
  spawn = zed

agent:
  match = ChatGPT app_id
  spawn = ChatGPT launcher command
  global_only = true
```

实际 `app_id` 与启动命令以本机 niri 查询结果和 NixOS 安装方式为准，在实现阶段确认。

---

## 9.3 搜索优先实验 Noctalia

第一阶段不开发新 launcher。

先验证：

- windows provider 作为 global provider；
- application 与 window 结果的排序；
- 2–3 字符后 Enter 是否稳定；
- workspace provider 是否需要通过 dmenu/custom provider 补充。

只有实际体验不足时再实现薄扩展。

---

# 10. v0.5 之后仍待实测的问题

这些问题不阻塞当前实现：

## 当前功能体验

1. Browser / Terminal / Editor 的 Global Main 是否都实际高频；低频项后续可删除绑定。
2. 多 Local 使用 MRU 是否符合直觉；如果不合适，再实验循环或显式选择。
3. Summon Global Main 是否比 Jump 更自然；v0.5 默认 Summon。
4. Global Main 被 summon 后，原 workspace 是否真的完全不需要占位/恢复逻辑；v0.5 默认不需要。
5. Noctalia 的 window/application ranking 是否已经足够，还是需要薄统一 provider。
6. named workspace 是否需要自动命名。
7. workspace slot `1..9` 应固定还是允许动态映射。

## Future / Experimental

8. Semantic Alias 是否会自然保持少量高频对象，还是最终重新形成 mark 式维护负担？
9. Directional Activation 的箭头是否确实应该表示 target 的最终位置？
10. Directional Activation 在已有多 pane composition 中应该如何表现？
11. Directional Activation 的默认比例与 focus 策略是什么？
12. niri / Hyprland 上最自然的物理 chord 实现分别是什么？

---

# 11. 评估新快捷键的准则

新增任何键位前依次问：

1. 用户是否已经知道目标是什么？
2. 是否在制造第二套名字或位置记忆？
3. 是否与已有成熟默认键冲突？
4. 是否可以通过统一搜索解决，而不增加固定键？
5. 这个键是否真的足够高频，值得进入长期肌肉记忆？
6. modifier / direction 在其他键上是否保持一致语义？
7. 如果换掉 niri / Hyprland，这个快捷键的用户意义能否保持？
8. 新功能是否仍满足“创建后可遗忘”？

如果不能明显降低认知或操作成本，就不应加入核心规范。
