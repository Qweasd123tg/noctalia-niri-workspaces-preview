local function instance(connector, vertical)
  local tree, watch
  local commands = {}
  local contextConnector, contextVertical = connector, vertical
  local snapshot = {
    status = "ok", message = "",
    outputs = {
      { name = "eDP-1", width = 1440, height = 960, focused = false },
      { name = "DP-1", width = 1920, height = 1080, focused = true },
    },
    workspaces = {
      { id = 11, idx = 1, output = "eDP-1", is_active = true, active_window_id = 101 },
      { id = 21, idx = 1, output = "DP-1", is_active = true, active_window_id = 201 },
    },
    windows = {
      { id = 101, workspace_id = 11, layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } },
      { id = 201, workspace_id = 21, is_focused = true,
        layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } },
    },
  }
  local env = setmetatable({}, { __index = _G })
  env.noctalia = {
    getConfig = function(key)
      if key == "workspace_scope" then return "all" end
      if key == "output_scope" then return "current" end
      if key == "show_icons" then return false end
      return nil
    end,
    state = {
      get = function(key) if key == "workspace_preview_snapshot" then return snapshot end end,
      set = function() end,
      watch = function(_, fn) watch = fn end,
    },
    setUpdateInterval = function() end, nowMs = function() return 1000 end,
    removeFile = function() end,
    runAsync = function(command) commands[#commands + 1] = command; return true end,
  }
  env.ui = setmetatable({}, { __index = function(_, kind)
    return function(props, children) return { kind = kind, props = props or {}, children = children or {} } end
  end })
  env.barWidget = {
    outputName = function() return contextConnector end,
    isVertical = function() return contextVertical end,
    setTooltip = function() end,
    render = function(value) tree = value end,
  }
  assert(loadfile("widget.luau", "t", env))()
  return {
    read = function() return tree end,
    snapshot = snapshot,
    commands = commands,
    watch = function()
      -- Noctalia 5.0.1 state-watch events have a default ScriptSnapshot.
      contextConnector, contextVertical = nil, false
      watch(snapshot)
    end,
    refresh = function()
      contextConnector, contextVertical = connector, vertical
      env.onIpc("refresh")
    end,
  }
end

local function assertOwn(instance, id, vertical)
  local tree = instance.read()
  assert(tree.kind == (vertical and "column" or "row"), "bar orientation survives asynchronous callbacks")
  assert(#tree.children == 1 and tree.children[1].props.key == "workspace-" .. id,
    "each bar keeps its own workspaces, regardless of global focus")
end

local left = instance("eDP-1", true)
local right = instance("DP-1", false)
assertOwn(left, 11, true)
assertOwn(right, 21, false)
local leftClick = left.read().children[1].children[1].props.onClick
leftClick()
right.read().children[1].children[1].props.onClick()
assert(left.commands[1]:match(" 11$") and not left.commands[1]:find("focus%-monitor"),
  "left workspace uses its global id without a monitor-focus warp")
assert(right.commands[1]:match(" 21$") and not right.commands[1]:find("focus%-monitor"),
  "same index on the right still targets a different global id")
for _, view in ipairs({ left, right }) do
  view.snapshot.windows[1].is_focused = true
  view.snapshot.windows[2].is_focused = false
  view.snapshot.outputs[1].focused = true
  view.snapshot.outputs[2].focused = false
  view.watch()
end
assertOwn(left, 11, true)
assertOwn(right, 21, false)
for _, view in ipairs({ left, right }) do
  view.snapshot.windows[1].is_focused = false
  view.snapshot.windows[2].is_focused = true
  view.snapshot.outputs[1].focused = false
  view.snapshot.outputs[2].focused = true
  view.watch()
end
assertOwn(left, 11, true)
assertOwn(right, 21, false)

left.snapshot.workspaces[1] = { id = 11, idx = 3, output = "DP-1" }
leftClick()
assert(left.commands[2]:match(" 11$") and not left.commands[2]:find("focus%-monitor"),
  "global workspace id remains correct after moving or reordering")
table.remove(left.snapshot.workspaces, 1)
leftClick()
assert(#left.commands == 2, "a removed workspace cannot accidentally target another index")

-- A missing bar output must not borrow another monitor after hot-unplug.
left.snapshot.outputs = { left.snapshot.outputs[2] }
left.refresh()
assert(left.read().children[1].kind == "glyph", "disconnected bar output does not show a different monitor")
print("multi-monitor tests passed")
