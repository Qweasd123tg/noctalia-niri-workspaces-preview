-- Exercise the actual service-to-widget path with Niri's overview events.
local saved, stream, watch, rendered, renders = nil, nil, nil, nil, 0
local clock = 0
noctalia = {
  state = {
    get = function(key) if key == "workspace_preview_snapshot" then return saved end end,
    set = function(key, value)
      if key == "workspace_preview_snapshot" then
        saved = value
        if watch then watch(value) end
      end
    end,
    watch = function(_, callback) watch = callback end,
  },
  outputs = function() return { { name = "eDP-1", width = 1440, height = 960, focused = true } } end,
  commandExists = function() return true end,
  runStream = function(_, callback) stream = callback; return true end,
  json = { decode = function(value) return value end },
  getConfig = function(key)
    if key == "workspace_scope" then return "all" end
    if key == "show_icons" then return false end
    if key == "active_color" then return "outline" end
    if key == "hide_empty_trailing_workspace" then return false end
    return nil
  end,
  nowMs = function() return clock end,
  setUpdateInterval = function() end,
  removeFile = function() end,
}
ui = setmetatable({}, { __index = function(_, kind)
  return function(props, children) return { kind = kind, props = props or {}, children = children or {} } end
end })
barWidget = {
  outputName = function() return "eDP-1" end,
  isVertical = function() return false end,
  setTooltip = function() end,
  render = function(tree) rendered = tree; renders = renders + 1 end,
}
local function find(node, key)
  if node.props.key == key then return node.props end
  for _, child in ipairs(node.children) do
    local result = find(child, key)
    if result then return result end
  end
end
local function map(id) return find(rendered, "output-eDP-1-workspace-" .. id) end
local function window(id) return find(rendered, "window-" .. id .. "-direct") end

assert(loadfile("service.luau"))()
stream({ WorkspacesChanged = { workspaces = {
  { id = 1, idx = 1, output = "eDP-1", is_active = true, is_focused = true, active_window_id = 11 },
  { id = 2, idx = 2, output = "eDP-1", active_window_id = 22 },
  { id = 3, idx = 3, output = "eDP-1" },
} } })
stream({ WindowsChanged = { windows = {
  { id = 11, workspace_id = 1, is_focused = true,
    layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } },
  { id = 22, workspace_id = 2,
    layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } },
} } })
stream({ OverviewOpenedOrClosed = { is_open = false } })
assert(loadfile("widget.luau"))()
assert(map(1).borderWidth == 0 and map(2).borderWidth == 0, "normal mode has no workspace frames")
assert(window(11).border == "primary", "normal window focus remains highlighted")

-- Niri clears focus before announcing overview. The map must redraw immediately.
stream({ WindowFocusChanged = {} })
local before = renders
stream({ OverviewOpenedOrClosed = { is_open = true } })
assert(saved.overview_open == true and renders == before + 1, "overview is published and rendered immediately")
assert(map(1).borderWidth == 1 and map(1).border == "primary", "selected map is outlined without window focus")
assert(map(2).borderWidth == 0 and map(3).borderWidth == 0, "other maps stay unoutlined")
assert(window(11).border ~= "primary" and window(22).border ~= "primary", "remembered windows do not get fake focus")

-- Keep geometry pending while navigating the overview.
stream({ WindowLayoutsChanged = { changes = { { 11, { tile_size = { 700, 900 } } } } } })
before = renders
stream({ WorkspaceActivated = { id = 2, focused = true } })
assert(renders == before + 1 and map(2).borderWidth == 1 and map(1).borderWidth == 0,
  "overview navigation updates synchronously during geometry bursts")
stream({ WorkspaceActivated = { id = 3, focused = true } })
assert(map(3).borderWidth == 1 and map(2).borderWidth == 0, "empty workspace also has an overview highlight")

stream({ OverviewOpenedOrClosed = { is_open = false } })
assert(saved.overview_open == false, "closing overview clears service state")
for id = 1, 3 do assert(map(id).borderWidth == 0, "overview frames disappear on exit") end
stream({ WorkspaceActivated = { id = 1, focused = true } })
stream({ WindowFocusChanged = { id = 11 } })
assert(window(11).border == "primary" and map(1).borderWidth == 0, "normal focus works after overview exit")
print("overview tests passed")
