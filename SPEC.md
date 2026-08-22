# Window Keybindings Specification

状态：**Draft v0.1**

本文定义窗口、工作区、搜索、实例作用域与布局组合的**用户语义**。实现可以由 niri IPC、Hyprland dispatcher、Noctalia、独立脚本或其他机制完成；实现细节不得反过来污染用户模型。

本文使用以下规范词：

- **必须**：实现若不满足，则不符合本规范。
- **应该**：强烈建议，只有明确理由时才偏离。
- **可以**：可选能力。

---

## 1. 总模型

用户面对的对象分为四层：

```text
Workspace
  ├─ Local role slots
  │    ├─ browser
  │    ├─ terminal
  │    ├─ editor
  │    └─ agent
  ├─ Ordinary windows
  ├─ Global-main windows（可被召回）
  └─ Visible composition（当前屏幕组合）
```

核心约束：

> **Window identity ≠ window position ≠ creation order ≠ MRU distance.**

窗口的左右顺序、当前 workspace 位置、历史距离都只能作为辅助信息，不能成为用户识别窗口的必要条件。

---

# 2. 设计原则

## 2.1 创建后可遗忘

### 规范

用户创建窗口后，不应为了未来再次访问它而额外执行 mark、重命名、移动到特定位置等管理动作。

### 原因

传统 mark 模型的问题不是功能不够，而是把管理成本推给用户：

1. 创建窗口；
2. 决定要不要 mark；
3. 给 mark 起名字；
4. 记住名字；
5. 窗口消失后维护或遗忘这个 mark。

而用户本来已经知道对象的自然名称，例如 `Firefox`、`Zed`、`nix-config`。搜索应复用已有语义记忆，而不是制造第二套名字。

---

## 2.2 已知目标必须直接寻址

### 规范

高频且稳定的目标应该拥有 O(1) 语义快捷键，例如：

```text
Mod+B → browser
Mod+T → terminal
Mod+E → editor
Mod+A → agent
```

### 原因

当用户脑中的意图是“我要浏览器”时：

```text
Mod+Left × 3
```

和：

```text
Mod+Tab × 4
```

都把一个已知目标退化为搜索问题。

固定角色键的价值不是节省一两次按键，而是取消“它在哪里”的认知步骤。

---

## 2.3 未知/长尾目标使用名称搜索

### 规范

不能为所有应用分配字母键。未固定为 role 的对象，必须可以通过名称搜索：

```text
Mod+Space
fi
Enter
```

典型目标：Firefox、Files、Spotify、Obsidian、某个具体终端标题、某个 named workspace。

搜索结果应该在通常情况下允许用户输入前 2–3 个字符后直接 Enter。

### 搜索排序必须稳定

建议优先级：

1. 当前 workspace 中的精确 role / app alias；
2. 当前 workspace 中的窗口；
3. named workspace；
4. global-main 实例；
5. 其他 workspace 的运行中窗口；
6. 已安装但未运行的应用。

同一查询在状态未变化时，不应随机改变第一项。

### 原因

“名字”是用户本来就拥有的知识；窗口位置和 MRU 距离是系统偶然状态。

---

## 2.4 切换与新建必须分离

这是本规范最重要的防重复规则之一。

### Switch-or-create

默认语义入口应当：

```text
已有合适实例 → 使用它
没有 → 创建
```

### Force-new

必须另有明确入口表达：

```text
我不是要去 Firefox；
我要再开一个 Firefox 窗口。
```

### 暂定

```text
Mod+Space → 搜索并 switch-or-create
Mod+D     → 搜索并 force-new
```

### 原因

`Mod+D` 沿用 niri 的“Run an Application”习惯，适合作为显式创建入口；`Mod+Space` 与 Noctalia launcher 的官方建议一致，空间键面积大、易触发，适合作为最常用的统一寻址入口。

如果应用本身不支持真正的新进程/新实例，`force-new` 至少必须请求“新窗口”；具体结果由应用能力决定。

---

# 3. Workspace 模型

## 3.1 Workspace 必须有名字

### 规范

用户长期使用的 workspace 应拥有语义名称，例如：

```text
main
window-keybindings
learning
media
game
```

workspace 的内部 ID、物理顺序和显示器位置不能成为身份。

### 原因

匿名 `workspace 4` 仍然要求用户建立额外映射：

```text
4 = window-keybindings
```

名字本身已经能够表达对象。

---

## 3.2 `1..9` 是快速别名，不是身份

### 规范

```text
Mod+1..9
```

应该保留，因为数字位于左手易达区，并且 niri / Hyprland 都有成熟的数字 workspace 使用习惯。

但数字必须被视为**稳定快捷槽位**，例如：

```text
1 → main
2 → current-project
3 → learning
4 → media
```

UI 应尽量显示：

```text
2: window-keybindings
```

而不是只显示 `2`。

### 原因

这样用户既可依赖肌肉记忆，也不会在忘记数字映射时失去访问能力；任何时候仍能按名字搜索。

---

## 3.3 Workspace 搜索是数字快捷键的兜底

### 规范

统一搜索入口必须支持 named workspace。

例如：

```text
Mod+Space
win
Enter
```

→ `window-keybindings`

因此不需要为每个 workspace 创建 mark，也不强迫所有 workspace 占据 `1..9`。

---

## 3.4 顺序遍历仅为辅助

### 暂定

```text
Mod+PageUp   → previous workspace
Mod+PageDown → next workspace
```

保留 niri 的成熟习惯，但它只能作为附近 workspace 的便利操作，不能成为主要寻址模型。

---

# 4. Role 模型

## 4.1 Role 不是应用名

### 示例

```text
browser  → 当前可能由 Firefox 实现
terminal → 当前可能由 Ghostty 实现
editor   → 当前可能由 Zed 实现
agent    → 当前可能由某个终端/桌面应用实现
```

快捷键必须绑定 `browser` 这个用户意图，而不是硬编码“Firefox 永远是 B 的意义”。

### 原因

以后替换 Firefox、Ghostty、Zed 时，用户的肌肉记忆不应变化。

---

## 4.2 Local role

### 暂定快捷键

```text
Mod+B → 当前 workspace 的 browser
Mod+T → 当前 workspace 的 terminal
Mod+E → 当前 workspace 的 editor
Mod+A → 当前 workspace 的 agent
```

### 行为

以 `Mod+B` 为例：

1. 当前 workspace 已有被绑定为 local browser role 的实例 → 直接激活；
2. 当前 workspace 没有已绑定实例，但存在可认领的 browser 窗口 → 认领一个确定性的候选并激活；
3. 当前 workspace 完全没有 browser → 创建并绑定新的 local browser 实例。

### 多实例规则

普通情况下一个 workspace 对每个 role 只保留一个**role slot**。

用户仍然可以自由创建更多同类窗口；这些额外窗口只是 ordinary windows，不会让 `Mod+B` 的目标每次随 MRU 改变。

当已绑定实例关闭后，下一次调用可以：

1. 优先认领当前 workspace 最近明确使用过的匹配窗口；
2. 若没有则新建。

这一步必须是确定性的。

---

## 4.3 Global Main role

### 暂定快捷键

```text
Mod+Alt+B → global-main browser
Mod+Alt+T → global-main terminal
Mod+Alt+E → global-main editor（是否需要，待定）
Mod+Alt+A → global-main agent（是否需要，待定）
```

### `Alt` 的语法

本草案暂定：

> **Alt = 从 local scope 提升到 global-main scope。**

因此：

```text
Mod+B     = 本任务浏览器
Mod+Alt+B = 全局主浏览器
```

这是规则，而不是两个互不相关的快捷键。

---

## 4.4 Global Main 必须被“拉过来”，而不是让用户过去

### 规范

调用 `Mod+Alt+B` 时：

1. global-main browser 已存在 → 将该窗口移动/召回到当前 workspace 并聚焦；
2. 不存在 → 在当前 workspace 创建并注册为 global-main browser。

**禁止默认跳去它原来的 workspace。**

### 原因

如果系统把用户传送到主浏览器原来的 workspace，用户还必须记住“我刚刚从哪里来”。

把窗口拉进当前任务后：

```text
当前 editor
  ↓ Mod+Alt+B
主 browser 被拉入当前 workspace
  ↓ Mod+Tab
回到 editor
```

用户无需保存原 workspace 的位置。

### 重要推论

Global Main 是**可漫游对象**，其物理 workspace 不是身份的一部分。因此它不需要一个永恒的“home workspace”。

---

# 5. 普通窗口搜索

## 5.1 搜索的是对象，不只是应用

统一搜索应允许命中：

- role；
- 运行中应用；
- 具体窗口标题；
- named workspace；
- global-main 对象；
- 未运行应用。

结果应明确显示类型，例如：

```text
Firefox — GitHub                       [window · current]
Firefox — YouTube                      [window · workspace:media]
window-keybindings                     [workspace]
browser                                [role · local]
Firefox                                [application · new]
```

---

## 5.2 搜索默认不是“新建器”

`Mod+Space` 选择 `Firefox` 时，应该优先复用已有合适对象；只有不存在时才启动。

如果用户明确要新窗口，使用 `Mod+D`。

这样避免 launcher 同时承担“去已有应用”和“再制造一个实例”两种冲突语义。

---

# 6. 时间历史

## 6.1 `Mod+Tab` 只回答一个问题

> “回到刚才。”

### 暂定

```text
Mod+Tab       → previous/recent window
Mod+Shift+Tab → reverse recent traversal（可选）
Alt+Tab       → 可作为兼容别名
```

### 原因

niri 自 25.11 起原生 recent-window switcher 同时提供 `Alt+Tab` 和 `Mod+Tab`；Noctalia 的 Hyprland 示例使用 `Alt+Tab` 打开 window switcher。因此这是一种已有强肌肉记忆的语义。

但 MRU 不应承担“我要 Firefox”这种明确意图。

---

## 6.2 理想情况下历史恢复 view state

长期目标中，历史不只可以记窗口，还可以记用户刚才的**可见组合**。

例如：

```text
[ Editor | Terminal ]
      ↓ 临时进入 Browser solo
[ Browser ]
      ↓ Mod+Tab
[ Editor | Terminal ]
```

这一能力是 **SHOULD**，不是 v0.1 的 MUST，因为它比普通 MRU 需要更多状态管理。

---

# 7. 空间导航

## 7.1 `Mod+方向` 不再是主要窗口寻址方式

### 原因

如果用户必须记住：

```text
Browser 在 Editor 左边两格
```

则后台布局已经成为额外记忆负担。

因此方向键不能负责寻找任意后台窗口。

---

## 7.2 方向键仍然有价值：只处理“我看得到的邻居”

### 暂定

```text
Mod+←/→/↑/↓ → 在当前可见 composition 中移动焦点
```

### 原因

当两个窗口已经同时显示：

```text
[ Browser ][ Editor ]
```

“去左边窗口”不需要记忆，因为空间关系此刻就在屏幕上。

因此方向导航应该从“全 workspace 搜索方法”降级为“可见 composition 内的局部操作”。

### 对 niri 的影响

niri 默认方向操作可以滚动到屏幕外列。实现本规范时，可能需要限制/重定义方向行为，或者接受它作为兼容辅助，但不能要求用户依赖隐藏列顺序。

---

# 8. 可见布局：Composition 而不是后台顺序

## 8.1 后台窗口没有有意义的空间顺序

### 规范

用户离开一个窗口后，系统可以把它留在 compositor 的任意内部位置。只要：

- 语义快捷键仍能找到它；
- 搜索仍能找到它；
- 历史仍能回到它；
- 恢复显示时行为确定。

因此 niri 的横向 strip 在这一层未必是缺陷：如果后台列位置没有用户语义，它可以只是实现细节。

---

## 8.2 空间只在“同时可见”时成为语义

用户真正需要表达的是：

```text
只看 Browser
```

或者：

```text
保留 Editor，同时把 Browser 放旁边
```

而不是维护整个 workspace 的永久二维地图。

---

# 9. Plain activation 与 Compose activation

这是当前最需要人工验证的一部分。

## 9.1 Plain activation

例如：

```text
Mod+B
```

语义：

> “现在主要看 browser。”

暂定默认行为：目标成为当前主视图；如果目标已经可见，仅聚焦而不做多余重排。

是否应该在所有情况下强制回到单窗口/最大化视图，**尚未定案**。

---

## 9.2 Compose activation

语义：

> “保留当前窗口，同时把目标加入可见区域。”

本草案暂定使用 `Shift` 表达“保留并组合”：

```text
Mod+Shift+B     → 保留当前窗口，并加入 local browser
Mod+Alt+Shift+B → 保留当前窗口，并加入 global-main browser
```

### 为什么暂定用 Shift

这是一个语法一致的 modifier：

```text
Mod+B           local + plain
Mod+Alt+B       global + plain
Mod+Shift+B     local + compose
Mod+Alt+Shift+B global + compose
```

用户只需学习：

- `Alt` 改作用域；
- `Shift` 改呈现方式。

而不需要给每个 role 再发明一个独立键。

---

## 9.3 为什么 v0.1 暂不采用“Mod+Left+B”这种直接和方向组合的物理键

概念上它很自然：

```text
+Left = 新窗口在左边
```

但真实键盘绑定系统通常只天然处理：

```text
修饰键 + 一个主键
```

`Left+B` 同时包含两个非 modifier 键，对 niri/Hyprland 的直接绑定都不自然，往往需要 submap/leader/mode。

因此规范层保留“向左/右/上/下加入目标”的**语义动作**，但 v0.1 的默认物理绑定先不强行确定。

---

# 10. Split 方向与比例

## 10.1 最小默认方案

`Compose activation` 默认形成 50/50 二分屏：

```text
[ Current ][ Target ]
```

Target 默认位于右侧。

理由：

- 对代码工作流，当前对象通常是主上下文；
- 新对象多为参考/终端/浏览器；
- 固定默认比每次询问方向更快。

此项是暂定，不是最终结论。

---

## 10.2 重排与 resize 应进入结构操作层

暂定：

```text
Mod+Shift+方向 → 移动当前可见 pane / 调整相对位置
Mod+R          → 进入 resize mode
  ←/→/↑/↓      → 调整边界
  Enter/Esc    → 退出
```

### 原因

`R = Resize` 语义直接；niri 已把 `Mod+R` 用于列宽预设，Hyprland 文档也使用 resize submap 示例，因此“R 与尺寸调整”已有先例。

低频结构操作适合 mode；高频导航不适合 mode。

---

# 11. Fullscreen / maximize / floating

暂定：

```text
Mod+F       → maximize / solo presentation
Mod+Shift+F → true fullscreen
Mod+V       → toggle floating
```

### 理由

- `F` 对 Fullscreen/Fill 具有自然助记；
- niri 默认 `Mod+Shift+F` 就是真 fullscreen；
- niri 默认 `Mod+V` 为 floating toggle，Hyprland 默认示例也长期使用 `SUPER+V` 切换 floating。

规范需要区分：

- **maximize/solo**：保留桌面 shell/bar 的工作模式；
- **true fullscreen**：应用占满输出，适合视频/游戏。

---

# 12. 关闭窗口

暂定：

```text
Mod+Q → close current window
```

### 理由

`Q = Quit`，且 niri 默认即使用 `Mod+Q` 关闭当前窗口。

关闭 role-bound 窗口时，role slot 自动释放；下次调用 role 时按正常规则认领或创建。

---

# 13. Modifier 语法

v0.1 暂定：

| Modifier | 语义 |
|---|---|
| `Mod` | compositor / window-system 级操作 |
| `Alt` | 从 local scope 提升到 global-main scope |
| `Shift` | 结构变体：保留当前对象并 compose / 或移动 |
| `Ctrl` | move/send 当前对象到目标（主要用于 workspace/monitor） |

### `Ctrl` 的来源

niri 官方默认有非常一致的规则：

> 一个快捷键如果是“切换到某处”，加 `Ctrl` 通常就是“把当前窗口/列移动到那里”。

本规范保留这个非常优秀的语法思想。

例如：

```text
Mod+2      → 去 workspace slot 2
Mod+Ctrl+2 → 把当前窗口送到 workspace slot 2
```

是否随后跟随窗口切换 workspace，可作为实现设置，但默认应该保持用户当前上下文不变，减少意外跳转。

---

# 14. 暂定快捷键表

## 14.1 核心寻址

| 快捷键 | 暂定语义 | 理由 |
|---|---|---|
| `Mod+Space` | 统一搜索：window / role / workspace / app，优先复用，不存在则启动 | Noctalia 官方 launcher 使用 `Mod+Space`；空格易按、适合最高频入口 |
| `Mod+D` | 搜索应用并明确新建窗口/实例 | niri 默认 `Mod+D` 是 Run Application；将其收窄为 deliberate create 可消除“切换还是新建”歧义 |
| `Mod+Tab` | 回到 previous/recent window | niri 原生；符合成熟 Alt-Tab 时间导航语义 |
| `Alt+Tab` | 可选兼容别名 / Noctalia window switcher | 传统桌面强肌肉记忆；Noctalia 官方 Hyprland 示例使用 |

## 14.2 Roles

| 快捷键 | 语义 | 助记 |
|---|---|---|
| `Mod+B` | local browser | **B**rowser |
| `Mod+T` | local terminal | **T**erminal；同时继承 niri 默认终端键 |
| `Mod+E` | local editor | **E**ditor |
| `Mod+A` | local agent | **A**gent |
| `Mod+Alt+B/T/E/A` | 对应 global-main role | `Alt` = global scope |
| `Mod+Shift+B/T/E/A` | local role compose 到当前可见布局 | `Shift` = preserve + compose |
| `Mod+Alt+Shift+B/T/E/A` | global-main role compose | 作用域与呈现方式正交组合 |

## 14.3 Workspaces

| 快捷键 | 语义 |
|---|---|
| `Mod+1..9` | 进入语义 workspace slot |
| `Mod+Ctrl+1..9` | 把当前窗口送入对应 slot |
| `Mod+PageUp/PageDown` | 顺序访问前/后 workspace，仅作为辅助 |

## 14.4 可见布局

| 快捷键 | 语义 |
|---|---|
| `Mod+方向` | 仅在当前可见 composition 内切换 pane |
| `Mod+Shift+方向` | 重排当前可见 pane / 结构移动 |
| `Mod+R` | resize mode |
| `Mod+F` | maximize / solo presentation |
| `Mod+Shift+F` | true fullscreen |
| `Mod+V` | floating toggle |
| `Mod+Q` | close |

---

# 15. 失败与边界条件

## 15.1 单实例应用

有些应用不允许真正创建第二进程，`force-new` 只能请求新窗口。规范定义的是用户意图，不保证应用违反自身模型。

---

## 15.2 app identity 不稳定

Wayland `app_id`、XWayland class、窗口 title、浏览器 profile 可能不同。

因此实现层应该维护 role/application registry，而不是把一个正则表达式当成用户语义本身。

---

## 15.3 浏览器多 profile

未来可能需要：

```text
browser.personal
browser.work
browser.docs
```

但 v0.1 不应过早引入大量固定 role 快捷键。长尾 profile 应先由搜索解决。

---

## 15.4 多个匹配窗口

不得每次偷偷选择不同的 MRU 窗口作为 role。

role slot 一旦绑定实例，在其存活期间应该保持稳定。

普通 search 则可以显示所有具体窗口供用户选择。

---

## 15.5 Global Main 被另一个 workspace 使用

调用 global-main 意味着**对象漫游**。

如果 workspace A 正在使用 global browser，而 workspace B 调用 `Mod+Alt+B`，browser 可以从 A 被拉到 B。

这不是丢失状态，因为它的身份从来不是“workspace A 的那个窗口”。

如果用户需要 A/B 同时拥有浏览器，应使用各自的 local browser role。

---

## 15.6 启动异步

应用 spawn 后窗口可能延迟创建。实现应该监听 compositor event stream / window events 并在目标窗口真正出现后绑定 role，而不是依赖脆弱的固定 sleep。

---

# 16. niri 与本规范

niri 的一维横向 strip 并不会天然破坏本设计，因为本设计明确规定：

> 后台窗口的顺序没有用户语义。

niri 已有：

- named workspace；
- windows/workspaces JSON IPC；
- focus-window by ID；
- move-window-to-workspace；
- recent windows；
- fullscreen / maximize / tiling / floating 操作。

因此语义寻址、local/global role、搜索和召回都可以建立在 IPC 之上。

niri 真正需要绕过的是：默认 `Mod+方向` 会沿无限 strip 找到屏幕外窗口，而本规范希望方向只代表当前可见 composition。

此外二维 split composition 在 niri 上需要把“列 + 同列窗口 + 宽高”组合成高级动作，不如 Hyprland 的布局树/主从布局天然。

结论：

- **语义层：niri 足够。**
- **composition 层：可实现，但需要额外适配。**

---

# 17. Hyprland 与本规范

Hyprland 原生提供：

- named workspaces；
- special workspace；
- `focuswindow`；
- move-to-workspace；
- window tags/rules；
- directional focus；
- master layout；
- submaps/modes。

因此它更适合作为本规范的完整实验后端，尤其是：

- explicit split；
- master/secondary composition；
- resize mode；
- one-shot placement；
- global-main summon。

但本规范不应该直接复制 Hyprland 的默认布局模型，因为我们不希望后台窗口树本身成为用户必须记住的结构。

---

# 18. Noctalia 与本规范

Noctalia 更适合作为：

- 搜索 UI；
- launcher；
- window switcher；
- workspace/role 状态展示；
- shell IPC 前端。

而 compositor / helper 负责真正的：

- focus；
- move；
- spawn；
- role registry；
- layout composition。

本规范暂定保留 Noctalia 官方常见的：

```text
Mod+Space → launcher/search
Alt+Tab   → window switcher compatibility
```

但扩展 `Mod+Space` 的语义为“统一对象搜索”，而不仅仅是应用启动器。

---

# 19. 尚未解决的问题

以下问题在实现前必须继续讨论：

1. Plain role activation 是否应默认把目标变成单窗口主视图？
2. 已经存在 50/50 split 时，`Mod+B` 应只 focus browser，还是替换当前 pane，还是 collapse 到 solo？
3. Compose 默认目标在右侧是否足够自然？是否需要方向前缀？
4. 是否需要一套 one-shot placement mode，例如 `Mod+\` → `Left` → target？
5. `Mod+E = Editor` 会与不少桌面“Explorer/File Manager”习惯冲突，是否值得保留？
6. `Mod+D` 强制新建与 Noctalia/其他 launcher 的现有入口如何区分 UI？
7. 工作区 slot `1..9` 是固定类别（main/project/media），还是用户动态绑定 named workspace？
8. 多显示器中 named workspace 是全局唯一还是 output-local？
9. global-main 召回是否需要在某些情况下复制/新建，而不是移动？
10. history 是否需要恢复完整 composition，而不是只恢复 focus？
11. local role 自动认领现有匹配窗口的具体确定性规则是什么？
12. 是否应该给窗口搜索与 workspace 搜索提供可选前缀，但默认不需要输入？

这些问题应该通过实际键盘使用验证，而不是为了追求理论完整性一次性复杂化。

---

# 20. 最终设计准则

评估任何新快捷键或行为时，依次问：

1. 用户是否已经知道自己想要哪个对象？如果知道，为什么还要搜索位置？
2. 这个动作是否要求用户记住窗口的偶然状态？
3. 创建之后是否产生了新的维护义务？
4. 相同 modifier 在其他键上是否保持同一语义？
5. 操作完成后，用户是否需要记住“我从哪里来”？
6. 这个行为是在表达用户意图，还是在暴露 compositor 的内部数据结构？
7. 如果换掉 niri/Hyprland，这个快捷键的用户意义还能保持不变吗？

只有当答案仍然简单、稳定、可预测时，才应该加入规范。
