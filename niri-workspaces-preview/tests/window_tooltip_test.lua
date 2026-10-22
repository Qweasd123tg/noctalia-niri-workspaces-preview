local tooltip, tree, watch
local snapshot = {
  status = "ok", message = "",
  outputs = { { name = "eDP-1", width = 1440, height = 960, focused = true } },
  workspaces = { { id = 11, idx = 2, name = "work", output = "eDP-1", is_active = true } },
  windows = {
    { id = 101, workspace_id = 11, app_id = "org.mozilla.firefox", title = "Report",
      layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } },
    { id = 102, workspace_id = 11, app_id = "terminal", title = "Build",
      layout = { pos_in_scrolling_layout = { 2, 1 }, tile_size = { 600, 450 } } },
    { id = 103, workspace_id = 11, app_id = "terminal", title = "Logs",
      layout = { pos_in_scrolling_layout = { 2, 2 }, tile_size = { 600, 450 } } },
  },
}
noctalia = {
  getConfig = function(key)
    if key == "workspace_scope" then return "all" end
    if key == "show_icons" or key == "highlight_hovered" then return false end
    return nil
  end,
  state = {
    get = function(key) if key == "workspace_preview_snapshot" then return snapshot end end,
    set = function() end,
    watch = function(_, fn) watch = fn end,
  },
  nowMs = function() return 1000 end,
  setUpdateInterval = function() end,
  removeFile = function() end,
}
ui = setmetatable({}, { __index = function(_, kind)
  return function(props, children) return { kind = kind, props = props or {}, children = children or {} } end
end })
barWidget = {
  outputName = function() return "eDP-1" end,
  isVertical = function() return false end,
  render = function(value) tree = value end,
  setTooltip = function(value) tooltip = value end,
}
local function find(node, key)
  if node.props.key == key then return node end
  for _, child in ipairs(node.children) do
    local found = find(child, key)
    if found then return found end
  end
end
assert(loadfile("widget.luau"))()
assert(type(tooltip) == "table", "workspace summary when no window is hovered")
assert(find(tree, "window-101-direct").props.onHover == "onWindowHover", "tooltips work with visual highlights disabled")
onWindowHover("true", "window-101-direct")
assert(tooltip == "Report\norg.mozilla.firefox\n#2 · work · eDP-1", "window title, application and placement")
assert(find(tree, "window-101-direct").props.border == "outline", "tooltip does not enable visual hover highlighting")
snapshot.windows[1].title = "New report"
watch(snapshot)
onIpc("refresh")
assert(tooltip:find("New report", 1, true), "title updates are reflected while hovered")
snapshot.windows[1].title = nil
onIpc("refresh")
assert(tooltip == "org.mozilla.firefox\n#2 · work · eDP-1", "application fallback when title is absent")
onWindowHover("false", "window-101-direct")
assert(type(tooltip) == "table", "window leave restores the workspace summary")

local callback = find(tree, "column-2").props.onHover
assert(callback and _G[callback], "stack hover remains available without highlight tint")
_G[callback]("true")
assert(tooltip:find("Build", 1, true) and tooltip:find("Logs", 1, true), "stack tooltip lists its windows")
_G[callback]("false")
assert(type(tooltip) == "table", "stack leave restores the workspace summary")
print("window tooltip tests passed")
