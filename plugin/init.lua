--[[
This Plugin does the following:
- Provide the following key bindings to span the WextTerm window across all screens:
   Leader 1 -> 1/4 of all screens w.r.t. screens left edge
   Leader 2 -> 1/2 of all screens w.r.t. screens left edge
   Leader 3 -> 3/4 of all screens w.r.t. screens left edge
   Leader 4 -> 4/4 of all screens w.r.t. screens left edge
   Leader 5 -> 3/4 of all screens w.r.t. screens right edge
   Leader 6 -> 1/2 of all screens w.r.t. screens right edge
   Leader 7 -> 1/4 of all screens w.r.t. screens right edge
- Works on Ubuntu >=24.04 and when all the screens dimensions are identical.
- Considers the effects of these GNOME extensions on the default Ubuntu Panel:
  - openbar@neuromorph
  - hidetopbar@mathieu.bidon.ca

Written by: sunbearc22
Tested on: Ubuntu 24.04.3, wezterm 20251025-070338-b6e75fd7
]]
local M = {}

local wezterm = require("wezterm")

local function validate_git_repository(repo)
  -- Check if repo is a string
  if type(repo) ~= "string" then
    wezterm.log_error("[WS] Error: Input must be a string")
    return nil
  end
  -- Check for https:// protocol
  if string.sub(repo, 1, 8) == "https://" then
    local path = string.sub(repo, 9) -- Removed "https://"
    -- Exclude empty path
    if string.len(path) == 0 then
      wezterm.log_info("[WS] Error: URL path is empty after 'https://'")
      return nil
    end
    -- Exclude path w/o github%.com
    if not string.find(path, "github%.com") then
      wezterm.log_error("[WS] Error: URL does not contain 'github.com'.")
      return nil
    end
    -- -- Exclude inaccessible or invalid remote git repository
    -- local cmd = "git ls-remote -h " .. path
    -- local handle = io.popen(cmd)
    -- if handle then
    --   local result = handle:read("*a")
    --   handle:close()
    --   if result and string.len(result) > 0 then
    --     -- Valid remote repository
    --     wezterm.log_info("[WS] Valid remote repository: " .. repo)
    --     return true
    --   else
    --     wezterm.log_error("[WS] Error: Remote repository is inaccessible or invalid: " .. repo)
    --     return nil
    --   end
    -- else
    --   wezterm.log_error("[WS] Error: Failed to execute git command for: " .. repo)
    --   return nil
    -- end
    wezterm.log_info("[WS] Valid remote repository: " .. repo)
  else
    -- Check for file:// protocol
    if string.sub(repo, 1, 7) == "file://" then
      local path = string.sub(repo, 8) -- Remove "file://"
      -- Exclude empty path
      if string.len(path) == 0 then
        wezterm.log_error("[WS] Error: File path is empty after 'file://'")
        return nil
      end
      -- Basic validation that it's a valid file path (not just any string)
      if not string.find(path, "^[/%w%-%._~%+%$%@%(%):%[%]%{%}%|%\\]+$") then
        wezterm.log_error("[WS] Error: Invalid characters in file path.")
        return nil
      end
      -- Use test command to check if directory exists and is actually a directory
      local cmd = "test -d " .. path .. "/.git && echo 'valid_git_repo'"
      local handle = io.popen(cmd)
      if handle then
        local result = handle:read("*a")
        handle:close()
        if result and string.len(result) > 0 then
          wezterm.log_info("[WS] Valid local repository: " .. repo)
          return true -- Valid git repository
        else
          wezterm.log_error("[WS] Error: Invalid local git repository: " .. repo)
          return nil
        end
      end
    else
      -- Neither https:// nor file:// protocol found
      wezterm.log_error("[WS] Error: Missing 'https://' or 'file://' in " .. repo)
      return nil
    end
  end
end

---@param repo string?
local function find_plugin_package_path(repo)
  if not repo then
    return nil
  end

  if not validate_git_repository(repo) then
    return nil
  end

  local separator = package.config:sub(1, 1) == "\\" and "\\" or "/"

  for i, v in ipairs(wezterm.plugin.list()) do
    -- wezterm.log_info("[WS] " .. i .. " " .. v.url)
    if v.url == repo then
      return v.plugin_dir .. separator .. 'plugin' .. separator .. '?.lua'
    end
  end

  -- Handle case where plugin is not found
  wezterm.log_error("[WS] Error: Plugin not found " .. repo)
  wezterm.log_error("[WS] Error: Make sure plugin is in ~/.local/share/wezterm/plugins.")
  return nil
end

-- Find plugin path
local plugin = "https://github.com/sunbearc22/sb_window_spanning.wezterm.git"
local ppath = find_plugin_package_path(plugin)
-- Exit if plugin is no found
if not ppath then
  return
  -- else
  --   wezterm.log_info("[WS] ppath = " .. ppath)
end

-- Get plugin's parent directory (used to access other non Lua files that belongs to this plugin)
local ppath_parent = string.gsub(ppath, "%?%.lua$", "")
-- wezterm.log_info("[WS] ppath_parent = " .. ppath_parent)

-- Update package.path (This ensures files mentioned in require() can be located)
package.path = package.path .. ";" .. ppath
-- wezterm.log_info("[WS] package.path = " .. package.path)


function M.apply_to_config(config, opts)
  -- ws is abreviation for window_span
  local ws_mods = opts.ws_quarter_screens_mods or "LEADER"
  local ws_quarter_screens_key = opts.ws_quarter_screens_key or "1"
  local ws_half_screens_key = opts.ws_half_screens_key or "2"
  local ws_three_quarter_screens_key = opts.ws_three_quarter_screens_key or "3"
  local ws_all_screens_key = opts.ws_all_screens_key or "4"
  local ws_three_quarter_right_screens_key = opts.ws_three_quarter_screens_key or "5"
  local ws_half_right_screens_key = opts.ws_half_right_screens_key or "6"
  local ws_quarter_right_screens_key = opts.ws_quarter_right_screens_key or "7"

  local function get_openbar_height()
    local total_height = math.ceil(35 + 6.5 + 6.5) -- Open Bar default values
    local height_success, height_stdout, height_stderr = wezterm.run_child_process({ "gsettings", "get",
      "org.gnome.shell.extensions.openbar", "height" })
    local margin_success, margin_stdout, margin_stderr = wezterm.run_child_process({ "gsettings", "get",
      "org.gnome.shell.extensions.openbar", "margin" })
    local bmargin_success, bmargin_stdout, bmargin_stderr = wezterm.run_child_process({ "gsettings", "get",
      "org.gnome.shell.extensions.openbar", "bottom-margin" })
    if height_success and margin_success and bmargin_success then
      total_height = math.ceil(tonumber(height_stdout) + tonumber(margin_stdout) + tonumber(bmargin_stdout))
      wezterm.log_info("[WS] openbar@neuromorph total panel height = " .. total_height)
    else
      wezterm.log_error("[WS] openbar@neuromorph total_height cannot be calculated.")
    end
    return total_height
  end

  local function get_ubuntu_topbar_height()
    -- Ensure global variable for system theme is avaliable
    local theme = wezterm.GLOBAL.system.theme
    if not theme then
      wezterm.log_error(
        "[WS] Error: wezterm.GLOBAL.system.theme is nil. Check that plugin https://github.com/sunbearc22/sb_show_system_color.wezterm.git is installed.")
      return nil
    end
    -- wezterm.log_info("[WS] theme = " .. theme)

    -- Get Ubuntu Panel relative height from /usr/share/gnome-shell/theme/<theme>/gnome-shell.css
    -- using custom python script.
    local pyscript = ppath_parent .. "get_ubuntu_24.04_panel_height.py"
    -- wezterm.log_info("[WS] pyscript = " .. pyscript)
    local success, stdout, stderr = wezterm.run_child_process({ "python", pyscript, theme })
    local height = tonumber(2.2) -- units in em
    if success then
      -- Remove trailing whitespace and newlines
      local clean_output = string.gsub(stdout, "%s+$", "")
      -- wezterm.log_info("[WS] clean_output = " .. clean_output)
      -- Remove em
      clean_output = string.gsub(clean_output, "em", "")
      -- wezterm.log_info("[WS] clean_output = " .. clean_output)

      height = tonumber(clean_output)
      -- wezterm.log_info("[WS] height = " .. height)
    else
      wezterm.log_warn(
        "[WS] Fail to extract panel height from "
        .. pyscript
        .. ".\nUsing fallback value of 2.2em instead.\n"
        .. stderr
      )
    end

    -- Get base font size
    local base_font_size = tonumber("11") -- points  Default value.
    success, stdout, stderr = wezterm.run_child_process({ "gsettings", "get", "org.gnome.desktop.interface", "font-name" })
    if success then
      base_font_size = tonumber(string.match(stdout, "%d+"))
      -- wezterm.log_info("[WS] base_font_size = " .. base_font_size .. " points.")
    else
      wezterm.log_warn("[WS] Fail to get base font size. Using fallback value of 11 points instead. " .. stderr)
    end

    -- Calculate Ubuntus Panel absolute height
    local screens = wezterm.gui.screens()
    local main_screen_dpi = screens.main.effective_dpi
    -- wezterm.log_info("[WS] main_screen_dpi = " .. main_screen_dpi)
    local point_size = 1 / 72 -- in inches
    local tb_height = math.floor(base_font_size * main_screen_dpi * point_size * height)
    wezterm.log_info("[WS] Ubuntu Panel height = " .. tb_height)
    return tb_height
  end

  -- Function to check wheather the elements of arrary are identical
  local function all_equal(array)
    if #array == 0 then return true end
    local first = array[1]
    for i = 2, #array do
      if array[i] ~= first then
        return false
      end
    end
    return true
  end

  -- Handler for window-spanning event
  wezterm.on("window-spanning", function(window, pane, span_type)
    -- Find out how many screens the system has
    local screens = wezterm.gui.screens()
    local count = 0
    for _, _ in pairs(screens.by_name) do
      count = count + 1
    end
    -- If no screen
    if count == 0 then
      wezterm.log_error("[WS] No screen detected.")
      return
    else
      wezterm.log_info("[WS] Detected " .. count .. " screen(s).")
    end

    -- Find out whether the screens have equal size or not
    local scr_names, scr_widths, scr_heights, scr_xs = {}, {}, {}, {}
    -- Get reference dimensions from first screen
    for name, screen_info in pairs(screens.by_name) do
      table.insert(scr_names, name)
      table.insert(scr_widths, screen_info.width)
      table.insert(scr_heights, screen_info.height)
      table.insert(scr_xs, screen_info.x)
    end
    local screens_same_size = true
    if not (all_equal(scr_widths) and all_equal(scr_heights)) then
      screens_same_size = false
    end
    wezterm.log_info("[WS] screens_same_size = " .. tostring(screens_same_size))

    -- If screens have different sizes, quit event handler.
    if count > 0 and not screens_same_size then
      wezterm.log_warn("[WS] Screens have different orientation. Invalid for spanning.")
      return
    end

    -- Check whether these gnome-extensions that are related to the Panel or top-bar are enabled.
    local gnome_extensions = {
      ["openbar@neuromorph"] = false,
      ["hidetopbar@mathieu.bidon.ca"] = false,
    }
    local cmd = { "gnome-extensions", "list", "--enabled" }
    local success, stdout, stderr = wezterm.run_child_process(cmd)
    if success then
      -- Check whether these gnome-extensions are enabled
      for k, v in pairs(gnome_extensions) do
        local found = string.find(stdout, k)
        gnome_extensions[k] = (found ~= nil)
        if gnome_extensions[k] then
          wezterm.log_info("[WS] " .. k .. " is enabled.")
        end
      end
    end

    -- Get Panel height
    local panel_height = get_ubuntu_topbar_height() -- pixels. Ubuntu default panel
    if gnome_extensions['openbar@neuromorph'] then
      panel_height = get_openbar_height()           -- pixels
    end
    wezterm.log_info("[WS] Panel height = " .. panel_height)

    -- Wezterm window title bar height.
    -- Obtained by measurement.
    -- 1. Maximize the height of the window.
    -- 2. Subtract window:get_dimensions().pixel_height from wezterm.gui.screens().virtual_height
    local window_titlebar_height = 37
    wezterm.log_info("[WS] window_titlebar_height = " .. window_titlebar_height)

    -- Configure window dimensions and origin according to Keybinds
    local function get_primary_screen()
      local cmd = "xrandr --query | grep primary | cut -d' ' -f1"
      local handle = io.popen(cmd, "r")
      if not handle then
        wezterm.log_error("[WS] Error: Fail to get Primary Screen")
        return nil
      end
      local result = handle:read("*a")
      handle:close()
      -- Trim whitespace/newlines
      result = string.match(result, "^%s*(.-)%s*$")
      -- wezterm.log_info("[WS] result = " .. tostring(result))
      if not result or result == "" then
        wezterm.log_error("[WS] Error: Primary screen not found.")
        return nil
      end
      return result
    end

    -- Function to check whether x is in the primary screen.
    local function in_primary_screen(x)
      local primary_screen = get_primary_screen()
      if not primary_screen then return nil end
      local primary_screen_left_edge = 0
      local primary_screen_right_edge = 0
      for i, name in ipairs(scr_names) do
        -- wezterm.log_info("[WS] " .. i .. " " .. name)
        if name == primary_screen then
          primary_screen_left_edge = scr_xs[i]
          if primary_screen_left_edge == 0 then
            primary_screen_right_edge = scr_xs[i] + scr_widths[i] + 1
            break
          else
            primary_screen_left_edge = scr_xs[i] - 1
            primary_screen_right_edge = scr_xs[i] + scr_widths[i]
            break
          end
        end
      end
      -- wezterm.log_info("[WS] primary_screen_left_edge = " .. primary_screen_left_edge)
      -- wezterm.log_info("[WS] primary_screen_right_edge = " .. primary_screen_right_edge)
      if x >= primary_screen_left_edge and x <= primary_screen_right_edge then
        return true
      else
        return false
      end
    end

    -- Default values to span window across all screens
    local offset_x = 0
    local offset_y = 0
    local span_width = screens.virtual_width
    local span_height = screens.virtual_height - window_titlebar_height

    -- Define offset_x and span_width
    if span_type == "quarter" then
      offset_x = 0
      span_width = math.floor(span_width * 0.25)
    elseif span_type == "half" then
      offset_x = 0
      span_width = math.floor(span_width * 0.5) + 1
    elseif span_type == "three-quarter" then
      offset_x = 0
      span_width = math.floor(span_width * 0.75)
    elseif span_type == "all" then
      offset_x = 0
      span_width = span_width
    elseif span_type == "quarter-right" then
      offset_x = math.floor(span_width * 0.75)
      span_width = math.floor(span_width * 0.25)
    elseif span_type == "half-right" then
      offset_x = math.floor(span_width * 0.5) - 1
      span_width = math.floor(span_width * 0.5) + 1
    elseif span_type == "three-quarter-right" then
      offset_x = math.floor(span_width * 0.25)
      span_width = math.floor(span_width * 0.75)
    end

    -- Define offset_y and span_height
    local win_right_edge_x = offset_x + span_width
    if in_primary_screen(offset_x) and in_primary_screen(win_right_edge_x) then
      wezterm.log_info("[WS] In Primary Screen")
      if gnome_extensions['hidetopbar@mathieu.bidon.ca'] then
        offset_y = 0
        span_height = span_height
      elseif gnome_extensions['openbar@neuromorph'] then
        local cmd = { "gsettings", "get", "org.gnome.shell.extensions.openbar", "position" }
        success, stdout, stderr = wezterm.run_child_process(cmd)
        stdout = string.match(stdout, "^%s*(.-)%s*$")
        -- wezterm.log_info("[WS] stdout=" .. stdout)
        if string.find(stdout, "Top") then
          wezterm.log_info("[WS] Panel at the Top.")
          offset_y = panel_height + 1
          span_height = span_height - offset_y
        elseif string.find(stdout, "Bottom") then
          wezterm.log_info("[WS] Panel at the Bottom.")
          offset_y = 0
          span_height = span_height - panel_height - 1
        else
          wezterm.log_info("[WS] Neither Top or Bottom.")
        end
      else
        offset_y = panel_height + 1
        span_height = span_height - offset_y
      end
    else
      offset_y = 0
      span_height = span_height
    end

    -- Reposition & resize the window
    wezterm.log_info("[WS] Span geometry: x=" ..
      offset_x .. ", y=" .. offset_y .. ", span_width=" .. span_width .. ", span_height=" .. span_height)
    window:set_position(offset_x, offset_y)
    window:set_inner_size(span_width, span_height)
  end)

  -- Keys to span window across all screens
  local keys = {
    -- make window span across a quarter width of screens w.r.t. from left edge
    {
      key = ws_quarter_screens_key,
      mods = ws_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("window-spanning", window, pane, "quarter")
      end),
    },
    -- Make window span across half width of screens w.r.t. from left edge
    {
      key = ws_half_screens_key,
      mods = ws_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("window-spanning", window, pane, "half")
      end),
    },
    -- Make window span across three quarter width of screens w.r.t. from left edge
    {
      key = ws_three_quarter_screens_key,
      mods = ws_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("window-spanning", window, pane, "three-quarter")
      end),
    },
    -- Make window span across all screens w.r.t. from left edge
    {
      key = ws_all_screens_key,
      mods = ws_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("window-spanning", window, pane, "all")
      end),
    },
    -- Make window span across three quarter width of screens w.r.t. from right edge
    {
      key = ws_three_quarter_right_screens_key,
      mods = ws_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("window-spanning", window, pane, "three-quarter-right")
      end),
    },
    -- Make window span across half width of screens w.r.t. from right edge
    {
      key = ws_half_right_screens_key,
      mods = ws_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("window-spanning", window, pane, "half-right")
      end),
    },
    -- Make window span across a quarter width of screens w.r.t. from right edge
    {
      key = ws_quarter_right_screens_key,
      mods = ws_mods,
      action = wezterm.action_callback(function(window, pane)
        wezterm.emit("window-spanning", window, pane, "quarter-right")
      end),
    },
  }

  -- INSERT keys into config.keys
  if not config.keys then
    config.keys = {}
  end
  for i, key in ipairs(keys) do
    table.insert(config.keys, key)
    -- wezterm.log_info("[WS] Loaded key to config: " .. key.mods .. " " .. key.key)
  end
end

return M
