# Window Keybindings

一套面向键盘流桌面的窗口、工作区与搜索语义寻址规范，当前针对 niri 提供薄 helper。

当前规范：**Draft v0.7**。

## 核心模型

v0.7 删除 `Global Main` 与 `Mod+Alt+Role`。Role 只保留两类：

```text
Contextual
Browser / Terminal / Editor
→ Mod+Role
→ 只在当前 workspace 解析
→ 0=create，1=focus，2+=MRU

Singleton
Agent / Notes
→ Mod+Role
→ 全局解析
→ 已存在则 summon + focus
→ 不存在则 create
```

核心快捷键：

| 键 | 语义 |
|---|---|
| `Mod+B` | 当前 workspace Browser |
| `Mod+T` | 当前 workspace Terminal |
| `Mod+E` | 当前 workspace Editor |
| `Mod+A` | 全局 Agent / ChatGPT singleton |
| `Mod+N` | 全局 Notes / Obsidian singleton |
| `Mod+D` | Noctalia 统一搜索 |
| `Mod+Tab` | 最近窗口 / 回到刚才 |

不再定义 `Mod+Alt+B/T/E/A/N` 的 role 语义。

## 为什么删除 Global Main

`Browser Global Main`、`Terminal Global Main`、`Editor Global Main` 并没有稳定、天然的用户语义。多实例工具通常与 workspace/project 上下文绑定，只需要 contextual role；单实例或用户只需要一个实例的工具直接使用 singleton 即可。

真正需要跨 workspace 保持某个具体对象时，应把它建模为 **Semantic Alias / scratchpad**，例如 production SSH、logs、dashboard，而不是人为给整个 application role 指定一个 Main。

这一变化同时删除了 Global Main identity、runtime window-id registration 与等待 niri labels 才能完成 Browser Main 的必要性。niri 原生 labels 未来仍可用于 alias/scratchpad 等高级对象，但不再是核心 role 模型的 blocker。

## Helper

正式接口：

```text
window-keybindings contextual ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings singleton  ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings inspect
```

兼容 alias：

```text
local  → contextual
single → singleton
```

v0.7 删除：

```text
global
global-state
state
forget
reset
```

因此 helper 不再维护任何窗口 identity 状态。仍使用 `flock` 串行化快捷键动作，避免快速连按造成重复创建；锁不是窗口状态。

### Contextual

只在当前 focused workspace 中匹配 `APP_ID_REGEX`：

```text
0 → spawn
1 → focus
2+ → focus MRU
```

Browser / Terminal / Editor 使用这一策略。

### Singleton

全局匹配 `APP_ID_REGEX`：

```text
0 → spawn
1 → summon + focus
2+ → global MRU → summon + focus
```

ChatGPT 属于天然 singleton。Obsidian 当前属于 policy singleton：即使技术上偶尔能出现多个窗口，role 仍只解析成一个全局目标，多候选时用 MRU 消歧。

## Browser / 进程边界

窗口 identity 不依赖启动命令 PID。Chrome 等应用可能让新的命令行进程把“新建窗口”请求交给已有 browser process，因此 helper 的 spawn correlation 使用：

```text
before = 当前 niri window IDs
spawn command
wait until:
  出现新的 matching app_id
  且 window ID 不在 before
```

所以同一 browser process 下的多个 Chrome 窗口仍然可以作为独立 contextual windows 使用。

## Terminal 与 TUI

普通 Terminal 只匹配默认 Ghostty Wayland app_id：

```text
^com[.]mitchellh[.]ghostty$
```

独立 TUI 使用同一个 Ghostty renderer，但设置专用 app_id：

```bash
ghostty --class=dev.zaviro.tui.lazygit -e lazygit
ghostty --class=dev.zaviro.tui.yazi -e yazi
```

如果在普通 shell 中手动运行 `lazygit` / `yazi`，窗口仍然是 Terminal；role 由窗口创建 identity 决定，不检查 foreground process。

## 搜索与 Workspace

`Mod+D` 保持唯一主搜索入口，优先复用 Noctalia windows/application providers。长期 workspace 应有语义名称；`Mod+1..9` 只是快捷槽位，不是 workspace identity。

## Future / Experimental

- **Semantic Alias / scratchpad**：用于真正需要跨 workspace 保持具体 identity 的对象，例如 production SSH、logs、dashboard。
- **niri native labels/tags**：未来可作为 alias/scratchpad identity backend，但不是 v0.7 role 的依赖。
- **Directional Activation**：未来实验“保留当前窗口 + 激活目标 + 排列”。
- workspace 自动命名与更复杂多显示器 policy。

## Nix

仓库提供 `flake.nix`：

```bash
nix run github:zaviro/window-keybindings -- inspect
```

运行时依赖由 flake 提供：`niri`、`jq`、`flock`。

## 测试

`tests/test.sh` 使用 mock niri IPC 覆盖：

- contextual 当前 workspace MRU；
- contextual 缺失时创建新窗口；
- TUI app_id 不污染普通 Terminal；
- singleton 跨 workspace summon；
- policy singleton 多窗口时使用全局 MRU；
- singleton 缺失时创建；
- `local` / `single` compatibility aliases；
- helper 不再创建 Global Main runtime state。

## 文档

- `SPEC.md`：完整 v0.7 规范与设计理由。
- `REFERENCES.md`：niri、Noctalia 等参考依据。
- `index.html`：早期交互式草案，内容可能落后于 `SPEC.md`。
