# Niri Workspaces Preview for Noctalia

Compact, proportional maps of **all Niri workspaces** in the Noctalia bar,
including empty workspaces. Each map shows miniature windows with application
icons, and the workspace number doubles as a workspace switcher.

Derived from [Teagar's Niri Workspace Preview](https://github.com/noctalia-dev/community-plugins/tree/a8c5cd1c57ac3dc8a2048c86f5a6dcea71e0e3dd/niri-workspace-preview)
v1.1.0. This repository contains only that plugin and our changes, rather than
the full community-plugins repository. See [NOTICE](NOTICE) for provenance and
[LICENSE](LICENSE) for the MIT license.

## What changed

- Show every workspace on the selected monitor, ordered by workspace index.
- Keep empty workspaces visible and clickable.
- Click a workspace number or map background to switch to it; click a window
  miniature to focus that window.
- Highlight the active workspace number. In Niri's overview, also outline the
  selected workspace, even when it is empty and no window has keyboard focus.
- Update focus, overview and workspace selection immediately. Window geometry
  updates remain debounced to avoid flicker during animations and resizing.
- Keep the original output filters, floating-window modes, viewport options,
  icon lookup and scroll navigation.

The maps use window metadata from Niri IPC; they do not capture window contents.
One event-stream process feeds the plugin without compositor polling.

## Requirements

- Noctalia **v5**, with plugin API **17 or newer**. This is a Luau plugin;
  Noctalia Shell v4 is not supported.
- Niri on `PATH` and running as the compositor.
- Git for installation from a source repository.

Desktop-tested with Noctalia 5.0.1 and Niri 26.04 on a single monitor.
Output filtering also has automated tests; multiple physical monitors have not
been tested with this fork.

## Install

Add the repository as a Noctalia plugin source, then enable the plugin:

```sh
noctalia msg plugins source add niri-workspaces git https://github.com/Qweasd123tg/noctalia-niri-workspaces-preview
noctalia msg plugins enable qweasd123tg/niri-workspaces-preview
```

Alternatively, use **Settings → Plugins → Add source**, select a Git source,
and enter the repository URL. Enable **Niri Workspaces Preview**, then add its
**Preview** widget under **Settings → Bar**.

Choose **Workspace scope → All workspaces** in the widget settings. The default
remains `active` for compatibility with the original plugin.

If replacing the original plugin, remove its widget from the bar and disable it:

```sh
noctalia msg plugins disable teagar/niri-workspace-preview
```

Noctalia's source and plugin management is described in the
[official documentation](https://docs.noctalia.dev/noctalia/plugins/).

### Example configuration

Merge this widget definition into your Noctalia TOML configuration:

```toml
[widget.niri_preview]
type = "qweasd123tg/niri-workspaces-preview:preview"
workspace_scope = "all"
show_workspace_labels = true
output_scope = "current"
preview_size = 24
max_output_length = 160
workspace_gap = 6
show_icons = true
active_color = "outline"
```

Add `"niri_preview"` to your existing `[bar.default].start` list, then reload:

```sh
noctalia msg config-reload
```

`active_color = "outline"` gives remembered active windows on other workspaces
the normal outline. The window with keyboard focus keeps its separate primary
highlight. This matches the appearance used during development.

The built-in numeric workspace widget is optional: remove `"workspaces"` from
your bar list if you prefer the numbers supplied by this plugin.

## Update

```sh
noctalia msg plugins update niri-workspaces
```

Manually installed copies under `~/.local/share/noctalia/plugins/` take precedence
over Git sources. Move an existing development copy elsewhere if you want the
Git source to supply updates.

## Settings and development

[The plugin README](niri-workspaces-preview/README.md) documents the settings,
interaction behavior and implementation limits. The manifest is
[`niri-workspaces-preview/plugin.toml`](niri-workspaces-preview/plugin.toml).

For local development, clone this repository outside Noctalia's managed caches
and add it as a path source:

```sh
git clone https://github.com/Qweasd123tg/noctalia-niri-workspaces-preview
noctalia msg plugins source add niri-workspaces-dev path "$PWD/noctalia-niri-workspaces-preview"
noctalia msg plugins enable qweasd123tg/niri-workspaces-preview
```

Run the tests with Lua 5.4 and lint with Noctalia:

```sh
cd niri-workspaces-preview
lua tests/output_scope_test.lua
lua tests/workspace_scope_test.lua
lua tests/focus_latency_test.lua
lua tests/overview_test.lua
noctalia plugins lint .
```

The tests cover workspace ordering and clicks, empty workspaces, output filters,
immediate focus changes during geometry bursts, and opening, navigating and
closing Niri's overview.

## По-русски

Форк плагина Teagar для Noctalia v5: мини-карты всех рабочих столов Niri,
переключение по номеру или фону карты и переход к окну по его миниатюре.
В общем обзоре выбранный стол выделяется рамкой, включая пустые столы.
В обычном режиме остаются подсветка номера стола и окна в фокусе.

Для установки выполните две команды из раздела **Install**, добавьте виджет
в панель и выберите **All workspaces**. Пример выше повторяет настройки,
с которыми плагин проверялся на одном мониторе.
