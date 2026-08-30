# Window Keybindings

一套面向键盘流桌面的**窗口、工作区与搜索语义寻址规范**，当前针对 niri 提供可运行初版 helper。

当前规范：**Draft v0.6**。

## 核心模型

只保留三种主要寻址方式：

1. **知道角色** → 直接 role 键，例如 `Mod+B`、`Mod+T`、`Mod+A`。
2. **知道名字** → `Mod+D` 打开 Noctalia 统一搜索，选择 window / application / workspace。
3. **只想回到刚才** → `Mod+Tab` 使用 niri 最近窗口历史。

窗口物理位置、创建顺序和 MRU 距离都不是身份；MRU 仅用于多个已匹配候选的消歧。

## v0.6：modifier 只解决真实歧义

`Mod+Role` 优先表达“我要这个东西”。只有同一个 role 同时存在 Local 与 Global 两种 scope 时，才使用 `Alt` 选择 Global Main：

```text
Dual Scope
Mod+Role      → Local
Mod+Alt+Role  → Global Main

Global Singleton
Mod+Role      → Global Singleton
```

因此 Agent / ChatGPT 不再使用 `Mod+Alt+A`，而直接使用 `Mod+A`。Notes / Obsidian 当前也按 global singleton 处理，使用 `Mod+N`。

## v0.6 快捷键语义

| 键 | 语义 |
|---|---|
| `Mod+D` | Noctalia 统一搜索入口 |
| `Mod+B` | 当前 workspace local Browser；0=create，1=focus，2+=MRU |
| `Mod+T` | 当前 workspace local Terminal；排除 Global Main 与专用 TUI surface |
| `Mod+E` | 当前 workspace local Editor / Zed |
| `Mod+Alt+B` | Browser Global Main；summon-or-create |
| `Mod+Alt+T` | Terminal Global Main；summon-or-create |
| `Mod+Alt+E` | Editor Global Main；summon-or-create |
| `Mod+A` | Agent / ChatGPT Global Singleton；summon-or-create |
| `Mod+N` | Notes / Obsidian Global Singleton；summon-or-create |
| `Mod+Tab` | 最近窗口 / 回到刚才；保留 niri |

`Mod+Alt+A` 与 `Mod+Alt+N` 不再绑定，因为这两个 role 当前没有 Local/Global scope 歧义。

Global Main 与 Global Singleton 都采用 **Summon**：把对象拉到当前 workspace，而不是把用户跳到对象所在 workspace。

> 注意：当前 nix-config 中 `Mod+N` 曾用于 Noctalia Control Center。正式接入 v0.6 时需要迁移该旧绑定；规范优先保留 `N = Notes` 的高频直接入口。

## Role scope policy

```text
browser  → dual-scope
terminal → dual-scope
editor   → dual-scope
agent    → global-singleton
notes    → global-singleton
```

`global-singleton` 是用户语义策略，不要求底层应用技术上永远只能创建一个窗口。若偶尔出现多个匹配窗口，helper 默认取全局 MRU；如果未来真实使用需要多 scope，再把该 role 升级为 dual-scope。

## Identity / 状态优先级

实现必须按以下优先级选择窗口身份来源：

1. **窗口自身 `app_id` 能表达 → 绝不用外部状态。**
2. **单实例应用**（例如 ChatGPT）→ 直接使用天然唯一的 `app_id`。
3. **只有无法给不同实例赋不同 identity 的 GUI 应用** → 才允许临时使用 runtime state。
4. **niri 提供正式原生 window labels/tags/metadata 后** → 将剩余 fallback 迁移到 niri-native identity，并删除对应外部状态。

因此 runtime JSON 是兼容后端，不是默认架构。

例如 Terminal 可以直接区分：

```text
com.mitchellh.ghostty
→ Local Terminal

dev.zaviro.role.terminal-main
→ Terminal Global Main

dev.zaviro.tui.yazi
→ Yazi application surface
```

这三者都由窗口自身 identity 区分，不需要记录 window id。

## 初版 helper

[`bin/window-keybindings`](./bin/window-keybindings) 正式提供：

```text
window-keybindings local ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings global ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings global-state ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings singleton ROLE APP_ID_REGEX -- COMMAND [ARG...]
```

- `local`：Dual-Scope Local；当前 workspace 匹配，多个候选按 niri `focus_timestamp` 取 MRU，没有则 spawn。
- `global`：Dual-Scope Global Main 的首选后端；`APP_ID_REGEX` 描述 Global Main 自身专用 app_id；已有则 summon + focus，没有则 spawn；**不读写 Global Main JSON**。
- `global-state`：仅用于无法为 Global Main 暴露独立 identity 的应用；通过 session-local window id 登记。
- `singleton`：Global Singleton；全局查找，已有则 summon，没有则 spawn；多个候选取全局 MRU；不保存额外身份状态。

旧命令名 `single` 保留为兼容 alias，新配置统一使用 `singleton`。

只有 `global-state` fallback 会使用：

```text
$XDG_RUNTIME_DIR/window-keybindings/global-main.json
```

该文件只在当前登录会话有效。`flock` 只用于串行化快捷键动作，防止快速连按重复创建，不承担窗口 identity。

### 调试

```bash
window-keybindings inspect
window-keybindings state
window-keybindings forget terminal
window-keybindings reset
```

`state` 只显示 runtime fallback registrations；如果所有 role 都能由 app_id / singleton identity 表达，它应保持 `{}`。

## Terminal 与 TUI

普通 Terminal 只应匹配默认 Ghostty Wayland app_id：

```text
^com[.]mitchellh[.]ghostty$
```

独立 TUI 使用同一个 Ghostty，但设置专用 `class/app_id`：

```bash
ghostty --class=dev.zaviro.tui.lazygit -e lazygit
ghostty --class=dev.zaviro.tui.yazi -e yazi
```

Global Main Terminal 同理：

```bash
ghostty --class=dev.zaviro.role.terminal-main
```

因此 TUI 和 Terminal Global Main 天然不会参与 `Mod+T` 的 Local Terminal 查找。若在普通 shell 中手动运行 `lazygit` / `yazi`，窗口仍保持 Terminal 身份；helper 不检查 foreground process。

## Nix

仓库提供 `flake.nix`：

```bash
nix run github:zaviro/window-keybindings -- inspect
```

运行时依赖由 flake 提供：`niri`、`jq`、`flock`。

## 测试

[`tests/test.sh`](./tests/test.sh) 使用 mock niri IPC 覆盖：

- Local 按 app_id 匹配与 MRU；
- TUI app_id 不污染 Terminal；
- app_id-backed Global Main summon 且不产生状态登记；
- Global Singleton summon 且不产生状态登记；
- local/global 缺失时 spawn；
- `global-state` 仅作为显式 fallback；
- fallback Global Main 会从同 app_id 的 Local 查找中排除。

## Workspace 与搜索

长期 workspace 应有名字；`1..9` 只是快速槽位，不是身份。Noctalia 负责 UI，helper 只负责直接 role 行为，不另造 launcher。

## Future / Experimental

仍不阻塞初版实现的扩展包括：Semantic Alias、Directional Activation、workspace 自动命名与更复杂的多显示器 policy。

niri 原生 window labels/tags/metadata 一旦正式可用，应优先替换剩余 runtime-state fallback，而不是与 JSON 长期并存。

## 文档

- [`SPEC.md`](./SPEC.md)：完整 v0.6 规范与设计理由。
- [`REFERENCES.md`](./REFERENCES.md)：niri、Noctalia 等参考依据。
- [`index.html`](./index.html)：早期交互式草案入口；内容可能落后于 `SPEC.md`。
