# sb_window_spanning.wezterm

- This plugin provides 7 key bindings to span the WextTerm window across all screens in 7 different manners.
- Valid for Wezterm on Ubuntu >=24.04 and when all the screens dimensions are identical.
- Considers the effects of these GNOME extensions on the default Ubuntu Panel:
  - [openbar@neuromorph](https://github.com/neuromorph/openbar.git)
  - [hidetopbar@mathieu.bidon.cai](https://github.com/tuxor1337/hidetopbar.git)

_Note: Plugin [sb_show_system_color.wezterm](https://github.com/sunbearc22/sb_show_system_color.wezterm.git) must be in used before this plugin can be used._

## Installation & Usage

```lua
local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- Add these lines (to install and use the plugin with its default options):
local repo = "https://github.com/sunbearc22/sb_window_spanning.wezterm.git"
wezterm.plugin.require(repo).apply_to_config(config, {})

return config
```

## Options

**Default options**

```lua
local repo = "https://github.com/sunbearc22/sb_window_spanning.wezterm.git"
wezterm.plugin.require(repo).apply_to_config(config,
  {
    ws_mods = "LEADER",                         -- see key bindings
    ws_quarter_screens_key = "1",               -- see key bindings
    ws_half_screens_key = "2",                  -- see key bindings
    ws_three_quarter_screens_key = "3",         -- see key bindings
    ws_all_screens_key = "4",                   -- see key bindings
    ws_three_quarter_right_screens_key = "5",   -- see key bindings
    ws_half_right_screens_key = "6",            -- see key bindings
    ws_quarter_right_screens_key = "7",         -- see key bindings
  }
)
```

Change the value of these option fields to your preference.


## Key Bindings

**Default keys**

| Key Binding | Action |
| :----- | :------- |
| <kbd>LEADER</kbd><kbd>1</kbd> | span 1/4 of all screens w.r.t. screens left edge |
| <kbd>LEADER</kbd><kbd>2</kbd> | span 1/2 of all screens w.r.t. screens left edge |
| <kbd>LEADER</kbd><kbd>3</kbd> | span 3/4 of all screens w.r.t. screens left edge |
| <kbd>LEADER</kbd><kbd>4</kbd> | span 4/4 of all screens w.r.t. screens left edge |
| <kbd>LEADER</kbd><kbd>5</kbd> | span 3/4 of all screens w.r.t. screens right edge |
| <kbd>LEADER</kbd><kbd>6</kbd> | span 1/2 of all screens w.r.t. screens right edge |
| <kbd>LEADER</kbd><kbd>7</kbd> | span 1/4 of all screens w.r.t. screens right edge |

## Update

Press <kbd>CTRL</kbd><kbd>SHIFT</kbd><kbd>L</kbd> and run `wezterm.plugin.update_all()`.

## Removal

1. Press <kbd>CTRL</kbd><kbd>SHIFT</kbd><kbd>L</kbd> and run `wezterm.plugin.list()`.
2. Delete the `"plugin_dir"` directory of this plugin.
