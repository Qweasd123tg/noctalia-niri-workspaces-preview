local function setup(hide)
  local tree, watch
  local snapshot = {
    status = "ok", message = "",
    outputs = {
      { name = "eDP-1", width = 1440, height = 960, focused = true },
      { name = "DP-1", width = 1920, height = 1080 },
      { name = "HDMI-A-1", width = 1920, height = 1080 },
    },
    workspaces = {
      { id = 14, idx = 4, output = "eDP-1" },
      { id = 22, idx = 2, output = "DP-1" },
      { id = 11, idx = 1, output = "eDP-1", is_active = true, active_window_id = 101 },
      { id = 12, idx = 2, output = "eDP-1" },
      { id = 13, idx = 3, output = "eDP-1", active_window_id = 103 },
      { id = 21, idx = 1, output = "DP-1", is_active = true, active_window_id = 201 },
      { id = 31, idx = 1, output = "HDMI-A-1", is_active = true },
    },
    windows = {},
  }
  for _, pair in ipairs({ { 101, 11 }, { 103, 13 }, { 201, 21 } }) do
    snapshot.windows[#snapshot.windows + 1] = { id = pair[1], workspace_id = pair[2],
      layout = { pos_in_scrolling_layout = { 1, 1 }, tile_size = { 600, 900 } } }
  end
  local env = setmetatable({}, { __index = _G })
  env.noctalia = {
    getConfig = function(key)
      if key == "workspace_scope" or key == "output_scope" then return "all" end
      if key == "show_icons" then return false end
      if key == "hide_empty_trailing_workspace" then return hide end
      return nil
    end,
    state = {
      get = function(key) if key == "workspace_preview_snapshot" then return snapshot end end,
      set = function() end,
      watch = function(_, fn) watch = fn end,
    },
    setUpdateInterval = function() end, nowMs = function() return 1000 end,
    removeFile = function() end,
  }
  env.ui = setmetatable({}, { __index = function(_, kind)
    return function(props, children) return { kind = kind, props = props or {}, children = children or {} } end
  end })
  env.barWidget = {
    outputName = function() return "eDP-1" end,
    isVertical = function() return false end,
    setTooltip = function() end,
    render = function(value) tree = value end,
  }
  assert(loadfile("widget.luau", "t", env))()
  return snapshot, function() watch(snapshot); env.onIpc("refresh") end, function(id)
    for _, child in ipairs(tree.children) do
      if child.props.key == "workspace-" .. id then return true end
    end
    return false
  end
end

local snapshot, refresh, visible = setup(nil)
assert(not visible(14) and not visible(22), "trailing empty workspace is hidden separately on each output by default")
assert(visible(12), "an empty workspace in the middle stays visible")
assert(visible(31), "an entirely empty monitor keeps its active workspace")
assert(visible(11) and visible(13) and visible(21), "occupied workspaces remain visible")

snapshot.workspaces[1].is_active = true
refresh()
assert(visible(14), "the active empty trailing workspace remains visible")
snapshot.workspaces[1].is_active = false
snapshot.workspaces[1].name = "reserved"
refresh()
assert(visible(14), "a named trailing workspace remains visible")
snapshot.workspaces[1].name = nil
snapshot.windows[#snapshot.windows + 1] = { id = 104, workspace_id = 14, is_floating = true }
refresh()
assert(visible(14), "a floating window keeps the trailing workspace occupied even without an active-window id")
table.remove(snapshot.windows)
refresh()
assert(not visible(14), "closing the last window hides the inactive unnamed trailing workspace")

local _, _, showAll = setup(false)
assert(showAll(14) and showAll(22), "the setting can restore every empty trailing workspace")
print("trailing workspace tests passed")
