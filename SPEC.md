# Window Keybindings Specification

状态：**Draft v0.2**

本文定义窗口、工作区与搜索的用户语义。实现可以由 niri IPC、Hyprland dispatcher、Noctalia provider 或独立 helper 完成；实现细节不应反过来成为用户必须记住的东西。

---

# 1. 核心原则

## 1.1 创建后可遗忘

用户创建窗口后，不应为了未来再次访问它而 mark、额外命名或记住它的位置。

窗口的身份来自用户本来就知道的信息：应用名、窗口标题、role、workspace 名称。

> **Window identity ≠ window position ≠ creation order ≠ MRU distance.**

---

## 1.2 三种主要寻址方式

只保留三个高层入口：

### A. 已知角色：直接 role 键

```text
Mod+B → browser
Mod+T → terminal
```

用户已经知道“我要浏览器”时，不应再通过方向、Alt-Tab 次数或搜索位置寻找。

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
- 后续可扩展 role / global-main 对象。

通常输入前 2–3 个字符即可选择。

### C. 只想回到刚才：历史

```text
Mod+Tab
```

MRU 只回答“刚才那个是什么”，不承担寻找任意已知目标的职责。

---

# 2. 搜索模型

## 2.1 `Mod+D` 是唯一主搜索入口

v0.2 删除 `Mod+Space`。

原因：

- `Mod+Space` 与许多应用/输入法/桌面习惯容易冲突；
- 同时保留 `Mod+Space` 与 `Mod+D` 会制造两个高度重叠的搜索入口；
- niri 默认已经使用 `Mod+D` 表达 Run Application，扩展成 Destination / Discover 搜索比重新引入入口更自然。

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

因此搜索器不必替用户猜测“你要哪一个 Chrome”；匹配结果本身就表达目标对象。

如果 Noctalia 原生 ranking / provider 组合不足，再写一个薄 provider/plugin，而不是另造完整 launcher UI。

---

## 2.3 两字母快捷序列暂不进入核心规范

例如：

```text
Mod → F → I → Firefox
```

这种序列需要 leader/submap 系统，并不属于 niri 普通 `modifier + key` 绑定模型。

长尾应用暂时统一使用：

```text
Mod+D → 输入 2–3 字母 → Enter
```

只有真正达到高频、稳定且值得 O(1) 访问的对象，才升级成固定 role 键。

---

# 3. Role 模型

Role 表达的是用户意图，不是某个永久绑定的具体软件。

例如：

```text
browser  → 当前可能由 Google Chrome / Firefox 实现
terminal → 当前可能由 Ghostty 实现
editor   → 未来再决定
assistant → 未来再决定
```

---

## 3.1 Local role

### 暂定绑定

```text
Mod+B → 当前 workspace browser
Mod+T → 当前 workspace terminal
```

### 规范语义：focus-or-create

以 `Mod+B` 为例：

1. 当前 workspace 已有 local browser 实例 → focus；
2. 没有 local browser → 创建 browser；
3. 创建后该实例成为当前 workspace 的 local browser role slot。

`Mod+T` 同理。

### 注意

niri 官方默认的 `Mod+T` 是 `spawn terminal`，不是 focus-or-create。v0.2 在保留 `T = Terminal` 肌肉记忆的同时，**升级其用户语义**。

实现层可用 niri 官方 IPC 查询 windows、按 window ID focus；不存在时再 spawn。

---

## 3.2 Global-main role

### 暂定

```text
Mod+Alt+B → global-main browser
Mod+Alt+T → global-main terminal
```

`Alt` 暂定统一表示：

> 从当前 workspace 的 local role 提升到全局主实例。

### 行为

1. global-main 实例在当前 workspace → focus；
2. 存在但位于其他 workspace → **把窗口拉到当前 workspace 并 focus**；
3. 不存在 → 当前 workspace 创建并登记为 global-main。

核心原则：

> **移动对象，而不是移动用户。**

调用主实例后，不要求用户记住自己原先来自哪个 workspace。

---

## 3.3 `Mod+E` 与 `Mod+A`：保留语义槽位，暂不绑定

```text
E → Editor
A → AI / Assistant
```

目前不进入实际快捷键集合。

原因：

### Editor

编辑器生态仍快速变化，Zed、Neovim、AI coding tools 等的边界和使用方式并不稳定。没有必要提前把 `E` 固化成长期肌肉记忆。

### AI / Assistant

当前并没有稳定定义的“AI 窗口”：它可能是 ChatGPT 桌面应用、浏览器窗口、Claude Code/Codex 终端进程，或者未来完全不同的交互形态。

只有出现明确且高频的固定 AI 对象后，`Mod+A` 才应启用。

因此 E/A 现在只是 registry 中的保留命名，不占用物理键位。

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

因此数字提供肌肉记忆，名称提供可恢复的语义记忆。

---

## 4.3 自动命名属于 policy 层

niri 原生支持 named workspace、按名称 focus、运行时设置 workspace name。

“根据项目目录/第一个重要窗口自动给 workspace 命名”属于更高层 policy，可由 event-stream helper 实现，不应写死到 compositor 身份模型中。

---

# 5. niri 原生窗口管理能力全部保留

v0.2 不再试图用语义导航替换 niri 的空间操作系统。

原则：

> **语义寻址是新增层；原生窗口管理是可靠 fallback。**

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
- workspace 上下移动、重排；
- consume / expel；
- window height / column width 调整；
- center / expand 等。

即使高频场景很少使用某些键，也没有必要删掉。它们保留 compositor 的完整原生操作能力。

---

# 6. 删除的 v0.1 设计

## 6.1 删除 `Mod+Space`

理由见搜索模型：与 `Mod+D` 重复且冲突面更大。

## 6.2 删除 `Mod+Shift+Role = compose`

旧设计：

```text
Mod+Shift+B → 保留当前窗口并把 Browser 放旁边
```

删除原因：

- `Shift = compose` 并不直觉；
- 会与 niri 已存在的大量 Shift/结构移动语义混在一起；
- 分屏/组合属于布局层，不应绑死在 role 层；
- 用户对该语义产生疑惑本身就是失败信号。

分屏与组合后续单独设计，优先复用 niri / Hyprland 原生布局能力。

## 6.3 不限制 `Mod+方向` 只在可见窗口内

旧草案试图重新定义方向键，只让它处理当前可见 composition。

v0.2 取消这个限制。

niri 的原生方向导航、滚动 strip、窗口重排全部保留。即使语义搜索降低它们的使用频率，它们仍然是必要的底层窗口管理能力和回退方案。

---

# 7. 暂定快捷键表

## 7.1 语义寻址

| 快捷键 | 语义 | 状态 |
|---|---|---|
| `Mod+D` | Noctalia 统一搜索：window / application / 后续 workspace | 暂定 |
| `Mod+B` | local browser：focus-or-create | 暂定 |
| `Mod+T` | local terminal：focus-or-create | 暂定；保留 niri T=Terminal |
| `Mod+Alt+B` | global-main browser：summon-or-create | 暂定 |
| `Mod+Alt+T` | global-main terminal：summon-or-create | 暂定 |
| `Mod+E` | Editor role | **保留，不绑定** |
| `Mod+A` | AI / Assistant role | **保留，不绑定** |
| `Mod+Tab` | previous/recent window | 保留 niri |

## 7.2 Workspace

| 快捷键 | 语义 |
|---|---|
| `Mod+1..9` | named workspace 的快速槽位 |
| niri 原生 workspace 键 | 保留 |

## 7.3 原生窗口管理

`Mod+O/Q/F/R/V/Shift+F` 以及 niri 默认的方向、移动、重排、resize、consume/expel 等全部保留。

---

# 8. 实现边界

## 8.1 niri 默认 `spawn` 不会替我们做 focus-or-create

`Mod+T { spawn ... }` 的职责只是执行命令。

真正的 role 行为应由很薄的 helper 完成：

```text
key bind
  ↓
role helper
  ↓
query niri windows
  ├─ match → focus-window --id
  └─ no match → spawn
```

Global-main 再增加 move-window-to-workspace。

---

## 8.2 搜索优先实验 Noctalia

第一阶段不开发新 launcher。

先验证：

- windows provider 是否可以作为 global provider；
- application 与 window 结果的排序是否自然；
- 2–3 字符后 Enter 是否稳定；
- 是否能加入 workspace provider / 自定义 provider。

只有实际体验不足时再实现薄扩展。

---

# 9. 仍待验证的问题

1. `Mod+Alt+T` 的 global-main terminal 是否真的高频，还是只需要 browser global-main？
2. 一个 workspace 出现多个 browser 窗口时，哪个实例应成为 local browser role slot？
3. global-main 被拉走后，原 workspace 是否需要任何占位/恢复逻辑？
4. Noctalia 的 window/application ranking 是否已经足够，还是需要统一 provider？
5. named workspace 是否需要自动命名；如果需要，命名来源是项目目录、窗口标题还是手动搜索创建？
6. workspace slot `1..9` 应固定为类别还是允许动态映射？
7. 分屏/组合是否完全依赖 compositor 原生操作，还是以后需要一个独立的 one-shot placement 语义？
8. `Mod+E` / `Mod+A` 何时达到“值得启用”的真实使用频率？

---

# 10. 评估新快捷键的准则

新增任何键位前依次问：

1. 用户是否已经知道目标是什么？
2. 是否在制造第二套名字或位置记忆？
3. 是否与已有成熟默认键冲突？
4. 是否可以通过统一搜索解决，而不增加固定键？
5. 这个键是否真的足够高频，值得进入长期肌肉记忆？
6. modifier 在其他键上是否保持一致语义？
7. 如果换掉 niri / Hyprland，这个快捷键的用户意义能否保持？

如果不能明显降低认知或操作成本，就不应加入核心规范。