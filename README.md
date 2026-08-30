# Window Keybindings

一套面向键盘流桌面的**窗口、工作区与搜索语义寻址规范**，当前针对 niri 提供可运行初版 helper。

当前规范：**Draft v0.5**。

## 核心模型

只保留三种主要寻址方式：

1. **知道角色** → 直接 role 键，例如 `Mod+B`、`Mod+T`、`Mod+E`。
2. **知道名字** → `Mod+D` 打开 Noctalia 统一搜索，选择 window / application / workspace。
3. **只想回到刚才** → `Mod+Tab` 使用 niri 最近窗口历史。

窗口物理位置、创建顺序和 MRU 距离都不是身份；MRU 仅用于多个已匹配 Local Instance 的消歧。

## v0.5 快捷键语义

| 键 | 语义 |
|---|---|
| `Mod+D` | Noctalia 统一搜索入口 |
| `Mod+B` | 当前 workspace local Browser；0=create，1=focus，2+=MRU |
| `Mod+T` | 当前 workspace local Terminal；排除 Global Main 与专用 TUI surface |
| `Mod+E` | 当前 workspace local Editor / Zed |
| `Mod+Alt+B` | global-main Browser；summon-or-create |
| `Mod+Alt+T` | global-main Terminal；summon-or-create |
| `Mod+Alt+E` | global-main Editor；summon-or-create |
| `Mod+Alt+A` | global-only Agent / ChatGPT；single-instance summon-or-create |
| `Mod+A` | 不绑定 |
| `Mod+Tab` | 最近窗口 / 回到刚才；保留 niri |

Global Main 按 role 全局最多一个，语义上不属于任何 workspace。激活时采用 **Summon**：把对象拉到当前 workspace，而不是把用户跳到对象所在 workspace。

## 初版实现

[`bin/window-keybindings`](./bin/window-keybindings) 实现三种动作：

```text
window-keybindings local ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings global ROLE APP_ID_REGEX -- COMMAND [ARG...]
window-keybindings single ROLE APP_ID_REGEX -- COMMAND [ARG...]
```

- `local`：当前 workspace 匹配 role，排除其 Global Main；多个候选按 niri `focus_timestamp` 取 MRU；没有则 spawn。
- `global`：运行时登记一个 Global Main；已存在则 summon + focus，不存在则新建、登记、focus。
- `single`：用于 ChatGPT 一类 global-only 单实例应用；找到任意匹配窗口即 summon，没有才 spawn，不保存额外身份状态。

Global Main 状态仅保存在：

```text
$XDG_RUNTIME_DIR/window-keybindings/global-main.json
```

不会写入长期持久状态。`flock` 防止连续快速按键造成重复创建。

### 调试

```bash
window-keybindings inspect
window-keybindings state
window-keybindings forget terminal
window-keybindings reset
```

`inspect` 直接输出 niri 当前 windows/workspaces，可用于确认真实 `app_id`。

## Terminal 与 TUI

普通 Terminal 只应匹配默认 Ghostty Wayland app_id：

```text
^com[.]mitchellh[.]ghostty$
```

独立 TUI 使用同一个 Ghostty，但启动时设置专用 `class/app_id`：

```bash
ghostty --class=dev.zaviro.tui.lazygit -e lazygit
ghostty --class=dev.zaviro.tui.yazi -e yazi
```

因此这些 TUI 天然不会参与 `Mod+T` 的 Terminal role 查找。若在普通 shell 中手动运行 `lazygit` / `yazi`，窗口仍保持 Terminal 身份；helper 不检查 foreground process。

## Nix

仓库提供 `flake.nix`：

```bash
nix run github:zaviro/window-keybindings -- inspect
```

运行时依赖由 flake 提供：`niri`、`jq`、`flock`。

## 测试

[`tests/test.sh`](./tests/test.sh) 使用 mock niri IPC 覆盖：

- Local 排除 Global Main；
- TUI app_id 不污染 Terminal；
- Global Main focus / summon；
- global-only single-instance summon；
- local/global 缺失时 spawn；
- Global Main 运行时登记。

## Workspace 与搜索

长期 workspace 应有名字；`1..9` 只是快速槽位，不是身份。Noctalia 负责 UI，helper 只负责直接 role 行为，不另造 launcher。

## Future / Experimental

仍不阻塞初版实现的扩展包括：Semantic Alias、Directional Activation、workspace 自动命名与更复杂的多显示器 policy。

## 文档

- [`SPEC.md`](./SPEC.md)：完整 v0.5 规范与设计理由。
- [`REFERENCES.md`](./REFERENCES.md)：niri、Noctalia 等参考依据。
- [`index.html`](./index.html)：早期交互式草案入口；内容可能落后于 `SPEC.md`。
