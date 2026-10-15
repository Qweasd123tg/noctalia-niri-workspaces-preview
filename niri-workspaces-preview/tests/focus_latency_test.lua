local clock, rendered, renderCount, watch = 0, nil, 0, nil
local snapshot = {
  status = "ok",
  outputs = { { name = "eDP-1", width = 1440, height = 960, focused = true } },
  workspaces = { { id = 1, idx = 1, output = "eDP-1", is_active = true, is_focused = true } },
  windows = {
    { id = 1, workspace_id = 1, is_focused = true,
      layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } },
    { id = 2, workspace_id = 1, is_focused = false,
      layout = { pos_in_scrolling_layout = { 2, 1 }, tile_size = { 600, 900 } } },
  },
}
noctalia = {
  getConfig = function(key)
    if key == "workspace_scope" then return "all" end
    if key == "show_icons" then return false end
    return nil
  end,
  state = {
    get = function(key) if key == "workspace_preview_snapshot" then return snapshot end end,
    set = function() end,
    watch = function(_, callback) watch = callback end,
  },
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
  render = function(tree) rendered = tree; renderCount = renderCount + 1 end,
}
local function windowNode(node, id)
  if node.props.key == "window-" .. id .. "-direct" then return node end
  for _, child in ipairs(node.children) do
    local found = windowNode(child, id)
    if found then return found end
  end
end
local function border(id) return windowNode(rendered, id).props.border end
assert(loadfile("widget.luau"))()
assert(border(1) == "primary" and border(2) ~= "primary", "initial focus")

-- Geometry updates keep arriving while the compositor animates scrolling.
for _, time in ipairs({ 0, 40, 80 }) do
  clock = time
  snapshot.windows[1].layout.tile_size[1] = 600 + time
  watch(snapshot)
  update()
end
assert(renderCount == 1, "geometry bursts stay debounced")

clock = 81
snapshot.windows[1].is_focused = false
snapshot.windows[2].is_focused = true
watch(snapshot)
assert(renderCount == 2 and border(2) == "primary" and border(1) ~= "primary",
  "focus changes synchronously while geometry is still settling")

clock = 90
watch(snapshot)
clock = 100
snapshot.windows[1].is_focused = true
snapshot.windows[2].is_focused = false
watch(snapshot)
assert(renderCount == 3 and border(1) == "primary", "rapid focus changes are never queued behind layout")
clock = 150
update()
assert(renderCount == 3, "focus render cancels the stale deferred render")

for _, time in ipairs({ 160, 200, 240 }) do clock = time; watch(snapshot); update() end
assert(renderCount == 3, "geometry remains debounced after focus updates")
clock = 359
update()
assert(renderCount == 3, "geometry waits for the settle interval")
clock = 360
update()
assert(renderCount == 4 and border(1) == "primary", "latest geometry redraw preserves focus")

clock = 370
snapshot.windows[1].is_focused = false
watch(snapshot)
assert(renderCount == 5 and border(1) ~= "primary" and border(2) ~= "primary",
  "losing window focus also clears the highlight immediately")

print("focus latency tests passed")
