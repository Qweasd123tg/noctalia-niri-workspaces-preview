local function setup(invert, scope)
  local commands = {}
  local snapshot = {
    status = "ok", message = "",
    outputs = {
      { name = "eDP-1", width = 1440, height = 960 },
      { name = "DP-1", width = 1920, height = 1080, focused = true },
    },
    workspaces = {
      { id = 13, idx = 3, output = "eDP-1", active_window_id = 103 },
      { id = 21, idx = 1, output = "DP-1", is_active = true, is_focused = true, active_window_id = 201 },
      { id = 12, idx = 2, output = "eDP-1" },
      { id = 11, idx = 1, output = "eDP-1", is_active = true, active_window_id = 102 },
      { id = 14, idx = 4, output = "eDP-1" },
    },
    windows = {},
  }
  for _, values in ipairs({ { 101, 11, 1 }, { 102, 11, 2 }, { 103, 13, 1 }, { 104, 13, 3 }, { 201, 21, 1 } }) do
    snapshot.windows[#snapshot.windows + 1] = { id = values[1], workspace_id = values[2],
      layout = { pos_in_scrolling_layout = { values[3], 1 }, tile_size = { 600, 900 } } }
  end
  local env = setmetatable({}, { __index = _G })
  env.noctalia = {
    getConfig = function(key)
      if key == "workspace_scope" then return scope or "all" end
      if key == "output_scope" then return "current" end
      if key == "show_icons" then return false end
      if key == "invert_scroll" then return invert end
      return nil
    end,
    state = {
      get = function(key) if key == "workspace_preview_snapshot" then return snapshot end end,
      set = function() end,
      watch = function() end,
    },
    nowMs = function() return 1000 end,
    setUpdateInterval = function() end,
    runAsync = function(cmd)
      assert(not cmd:find("focus%-monitor"), "scrolling must not warp the pointer with focus-monitor")
      commands[#commands + 1] = cmd
      return true
    end,
    removeFile = function() end,
  }
  env.ui = setmetatable({}, { __index = function(_, kind)
    return function(props, children) return { kind = kind, props = props or {}, children = children or {} } end
  end })
  env.barWidget = {
    outputName = function() return "eDP-1" end,
    isVertical = function() return false end,
    render = function() end,
    setTooltip = function() end,
  }
  assert(loadfile("widget.luau", "t", env))()
  local function activate(id, windowId, focused)
    for _, workspace in ipairs(snapshot.workspaces) do
      if workspace.output == "eDP-1" then
        workspace.is_active = workspace.id == id
        workspace.is_focused = focused == true and workspace.id == id
        if workspace.id == id then workspace.active_window_id = windowId end
      end
    end
    for _, window in ipairs(snapshot.windows) do
      window.is_focused = focused == true and window.id == windowId
    end
  end
  local function scroll(steps, expected)
    env.onScroll("vertical", steps, true)
    assert(table.remove(commands, 1) == expected, "unexpected continuous scroll target: " .. tostring(expected))
    assert(#commands == 0)
  end
  return env, snapshot, activate, scroll
end

local env, snapshot, activate, scroll = setup(false)
-- The bar is on eDP-1 while global focus is on the other monitor.
scroll(1, "niri msg action focus-window --id 103")
activate(13, 103, true)
scroll(1, "niri msg action focus-column-right")
activate(13, 104, true)
scroll(1, nil) -- End of all occupied workspaces; do not enter the reserved empty one.
scroll(-1, "niri msg action focus-column-left")
activate(13, 103, true)
scroll(-1, "niri msg action focus-window --id 102")
activate(11, 102, true)
scroll(-1, "niri msg action focus-column-left")
activate(11, 101, true)
scroll(-1, nil)
scroll(0, nil)
scroll("invalid", nil)

-- Scrolling out of an empty workspace finds windows in either direction.
activate(12, nil, true)
scroll(1, "niri msg action focus-window --id 103")
scroll(-1, "niri msg action focus-window --id 102")

-- Navigation is independent of the display mode and global focus.
env, snapshot, activate, scroll = setup(false, "active")
scroll(1, "niri msg action focus-window --id 103")
activate(11, 101, false)
scroll(1, "niri msg action focus-window --id 102")

env, snapshot, activate, scroll = setup(true)
activate(13, 103, true)
scroll(1, "niri msg action focus-window --id 102")
activate(11, 102, true)
scroll(-1, "niri msg action focus-window --id 103")

-- Floating-only workspaces still provide a window to continue to.
env, snapshot, activate, scroll = setup(false)
snapshot.windows[3].is_floating = true
snapshot.windows[4].is_floating = true
scroll(1, "niri msg action focus-window --id 103")
print("continuous scroll navigation tests passed")
