# Niri Workspaces Preview for Noctalia

Compact, proportional maps of **all Niri workspaces** in the Noctalia bar,
including empty workspaces in use. Each map shows miniature windows with application
icons, and the workspace number doubles as a workspace switcher.

Derived from [Teagar's Niri Workspace Preview](https://github.com/noctalia-dev/community-plugins/tree/a8c5cd1c57ac3dc8a2048c86f5a6dcea71e0e3dd/niri-workspace-preview)
v1.1.0. This repository contains only that plugin and our changes, rather than
the full community-plugins repository. See [NOTICE](NOTICE) for provenance and
[LICENSE](LICENSE) for the MIT license.

## What changed

- Show every workspace on the selected monitor, ordered by workspace index.
- Hide each monitor's last unnamed, empty workspace by default. Active, named
  and other empty workspaces stay visible; a setting can show every workspace.
- Click a workspace number or map background to switch to it; click a window
  miniature to focus that window.
- Highlight the active workspace number. In Niri's overview, also outline the
  selected workspace, even when it is empty and no window has keyboard focus.
- Update focus, overview and workspace selection immediately. Window geometry
  updates remain debounced to avoid flicker during animations and resizing.
- Keep each bar attached to its own monitor during asynchronous state updates.
  Workspace clicks address global workspace IDs directly, avoiding the forced
  cursor centering caused by an extra `focus-monitor` action.
- Hover a window miniature for its title, application, workspace and monitor.
  Hovering a stacked column lists its windows, including with hover tint disabled.
- Scroll through columns and continue into the next or previous workspace
  when reaching the edge. Empty workspaces are skipped; scrolling stays on
  the bar's monitor and never calls `focus-monitor`.
- Keep the original output filters, floating-window modes, viewport options,
  icon lookup and scroll navigation.
- Enlarge application icons to 20 logical pixels by default, with an adjustable
  `icon_size` limit (8–48 px); smaller miniatures keep icons inside their bounds.

The maps use window metadata from Niri IPC; they do not capture window contents.
One event-stream process feeds the plugin without compositor polling.

## Requirements

- Noctalia **v5**, with plugin API **17 or newer**. This is a Luau plugin;
  Noctalia Shell v4 is not supported.
- Niri on `PATH` and running as the compositor.
- Python 3 for workspace-ID requests through Niri's local IPC socket.
- Git for installation from a source repository.

Desktop-tested with Noctalia 5.0.1 and Niri 26.04 on two monitors with different
scales. Automated tests cover multiple
widget instances, output filtering and missing context in asynchronous callbacks.

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
hide_empty_trailing_workspace = true
output_scope = "current"
preview_size = 24
max_output_length = 160
workspace_gap = 6
show_icons = true
icon_size = 20
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
lua tests/multi_monitor_test.lua
lua tests/trailing_workspace_test.lua
lua tests/scroll_navigation_test.lua
lua tests/window_tooltip_test.lua
python3 tests/workspace_ipc_test.py
noctalia plugins lint .
```

The tests cover workspace ordering and clicks, empty workspaces, output filters,
immediate focus changes during geometry bursts, and opening, navigating and
closing Niri's overview, per-monitor isolation during callbacks, monitor-aware
workspace clicks, trailing empty workspace visibility, and continuous scrolling
across workspace boundaries in both directions, window tooltips and workspace-ID
requests without changing desktop state during testing.

## По-русски

Форк плагина Teagar для Noctalia v5: мини-карты всех рабочих столов Niri,
переключение по номеру или фону карты и переход к окну по его миниатюре.
В общем обзоре выбранный стол выделяется рамкой, включая пустые столы.
В обычном режиме остаются подсветка номера стола и окна в фокусе.
Каждая панель сохраняет привязку к своему монитору. Последний пустой стол
на каждом мониторе скрыт по умолчанию; активный и именованный столы остаются
видимыми. Для показа всех столов отключите **Hide trailing empty workspace**.
Колесо перебирает колонки окон, а у края продолжает прокрутку на следующем
или предыдущем рабочем столе этого же монитора. Пустые столы пропускаются.
Подсказка при наведении показывает название окна, приложение, рабочий стол и
монитор. Клик по цифре обращается к ID стола напрямую, без лишнего `focus-monitor`.

Для установки выполните две команды из раздела **Install**, добавьте виджет
в панель и выберите **All workspaces**. Пример выше повторяет настройки,
с которыми плагин проверялся на одном и двух мониторах.
