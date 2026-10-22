local function run(scope, outputScope, vertical)
  local tree, tooltip, watched, commands = nil, nil, nil, {}
  local snapshot = {
    status = "ok", message = "",
    outputs = {
      { name = "eDP-1", width = 1440, height = 960, focused = true },
      { name = "DP-1", width = 1920, height = 1080 },
    },
    workspaces = {
      { id = 13, idx = 3, output = "eDP-1", is_active = false },
      { id = 12, idx = 2, output = "eDP-1", is_active = false },
      { id = 11, idx = 1, output = "eDP-1", is_active = true, active_window_id = 101 },
      { id = 21, idx = 1, output = "DP-1", is_active = true },
    },
    windows = {
      { id = 101, workspace_id = 11, is_focused = true,
        layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } },
      { id = 102, workspace_id = 12,
        layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 900, 900 } } },
    },
  }
  noctalia = {
    getConfig = function(key)
      if key == "workspace_scope" then return scope end
      if key == "output_scope" then return outputScope end
      if key == "show_icons" then return false end
      if key == "hide_empty_trailing_workspace" then return false end
      return nil
    end,
    state = {
      get = function(key) if key == "workspace_preview_snapshot" then return snapshot end end,
      set = function() end,
      watch = function(_, callback) watched = callback end,
    },
    setUpdateInterval = function() end, nowMs = function() return 1000 end,
    runAsync = function(command) commands[#commands + 1] = command; return true end,
    removeFile = function() end,
  }
  ui = setmetatable({}, { __index = function(_, kind)
    return function(props, children) return { kind = kind, props = props or {}, children = children or {} } end
  end })
  barWidget = {
    outputName = function() return "eDP-1" end,
    isVertical = function() return vertical == true end,
    render = function(value) tree = value end,
    setTooltip = function(value) tooltip = value end,
  }
  assert(loadfile("widget.luau"))()
  return function() return tree, tooltip end, snapshot, watched, commands
end

local function findKey(node, key)
  if node.props.key == key then return node end
  for _, child in ipairs(node.children) do
    local found = findKey(child, key)
    if found then return found end
  end
end

local read, snapshot, watched, commands = run("all", "current", false)
local tree, tooltip = read()
assert(#tree.children == 3, "all three workspaces on this monitor must be visible")
for index, id in ipairs({ 11, 12, 13 }) do
  assert(tree.children[index].props.key == "workspace-" .. id, "workspace index ordering")
  assert(tree.children[index].children[1].children[1].props.text == tostring(index), "workspace numbers")
end
assert(findKey(tree, "window-101-direct"), "active workspace window is present")
assert(findKey(tree, "window-102-direct"), "inactive workspace window is present")
assert(tree.children[1].children[1].children[1].props.color == "primary", "active workspace number")
assert(tree.children[2].children[1].children[1].props.color == "on_surface_variant", "inactive workspace number")
assert(#tooltip == 3 and tooltip[3].value:find("0 windows"), "empty workspace is represented")
tree.children[2].children[1].props.onClick()
findKey(tree, "output-eDP-1-workspace-13").props.onClick()
assert(commands[1]:match("^python3 %-c ") and commands[1]:match(" 12$") and not commands[1]:find("focus%-monitor"),
  "number click targets the global workspace id without moving the pointer")
assert(commands[2]:match(" 13$") and not commands[2]:find("focus%-monitor"),
  "empty map click also uses a global workspace id")

for _, workspace in ipairs(snapshot.workspaces) do workspace.is_active = workspace.id == 12 end
watched(snapshot)
onIpc("refresh")
tree = read()
assert(#tree.children == 3, "switching workspaces must retain every map")
assert(tree.children[2].children[1].children[1].props.color == "primary", "new active workspace number")
assert(tree.children[1].children[1].children[1].props.color == "on_surface_variant", "old active workspace number clears")

read = run("active", "current", false)
tree = read()
assert(#tree.children == 1 and findKey(tree, "window-101-direct"), "active-only compatibility")
assert(not findKey(tree, "window-102-direct"), "active-only excludes inactive windows")

read = run("all", "all", false)
assert(#(read()).children == 4, "all workspaces across selected monitors")
read = run("all", "current", true)
tree = read()
assert(tree.kind == "column" and #tree.children == 3, "vertical bar layout")
print("workspace scope tests passed")
