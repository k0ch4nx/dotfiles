---@type Wezterm
local wezterm = require("wezterm")

local config = wezterm.config_builder()

local color_scheme = "Kanagawa (Gogh)"
local socket_path = wezterm.home_dir .. "/.local/share/wezterm/sock"

config.unix_domains = {
    {
        name = "unix",
        socket_path = socket_path,
    },
}
config.default_gui_startup_args = { "connect", "unix" }

wezterm.plugin.update_all()

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup({
    options = {
        theme = color_scheme,
        theme_overrides = {},
        section_separators = {
            left = wezterm.nerdfonts.ple_upper_left_triangle,
            right = wezterm.nerdfonts.ple_upper_right_triangle,
        },
        component_separators = {
            left = wezterm.nerdfonts.pl_left_soft_divider,
            right = wezterm.nerdfonts.pl_right_soft_divider,
        },
        tab_separators = {
            left = wezterm.nerdfonts.ple_upper_left_triangle,
            right = wezterm.nerdfonts.ple_lower_right_triangle,
        },
    },
    sections = {
        tabline_a = { "mode" },
        tabline_b = { "workspace" },
        tabline_c = { " " },
        tab_active = { "index", { "process", padding = { left = 0, right = 1 } } },
        tab_inactive = { "index", { "process", padding = { left = 0, right = 1 } } },
        tabline_x = {},
        tabline_y = {},
        tabline_z = { "domain" },
    },
    extensions = {},
})

config.font_size = 22
config.scrollback_lines = 999999999
config.window_decorations = "TITLE|RESIZE|MACOS_USE_BACKGROUND_COLOR_AS_TITLEBAR_COLOR"
config.font = wezterm.font_with_fallback({
    "UDEV Gothic NFLG",
    -- "JetBrainsMono Nerd Font",
    -- "ヒラギノ丸ゴ ProN",
})
config.colors = {
    tab_bar = {
        background = "NONE",
    },
}
config.command_palette_font_size = config.font_size
config.command_palette_fg_color = wezterm.color.get_builtin_schemes()[color_scheme].foreground
config.command_palette_bg_color = wezterm.color.get_builtin_schemes()[color_scheme].ansi[1]
config.color_scheme = color_scheme
config.front_end = "OpenGL"
config.keys = {
    { key = "q", mods = "CMD", action = wezterm.action.QuitApplication },
    { key = "p", mods = "CTRL|SHIFT", action = wezterm.action.ActivateCommandPalette },
    { key = "n", mods = "CMD", action = wezterm.action.SpawnCommandInNewWindow },
    { key = "t", mods = "CMD", action = wezterm.action.SpawnCommandInNewTab({ cwd = wezterm.home_dir }) },
    { key = "w", mods = "CMD", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
    { key = "w", mods = "CTRL|SHIFT", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
    { key = "Tab", mods = "CTRL", action = wezterm.action.ActivateTabRelative(1) },
    { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
    { key = "1", mods = "CMD", action = wezterm.action.ActivateTab(0) },
    { key = "2", mods = "CMD", action = wezterm.action.ActivateTab(1) },
    { key = "3", mods = "CMD", action = wezterm.action.ActivateTab(2) },
    { key = "4", mods = "CMD", action = wezterm.action.ActivateTab(3) },
    { key = "5", mods = "CMD", action = wezterm.action.ActivateTab(4) },
    { key = "6", mods = "CMD", action = wezterm.action.ActivateTab(5) },
    { key = "7", mods = "CMD", action = wezterm.action.ActivateTab(6) },
    { key = "8", mods = "CMD", action = wezterm.action.ActivateTab(7) },
    { key = "9", mods = "CMD", action = wezterm.action.ActivateTab(-1) },
    { key = "c", mods = "CMD", action = wezterm.action.CopyTo("Clipboard") },
    { key = "v", mods = "CMD", action = wezterm.action.PasteFrom("Clipboard") },
    { key = "=", mods = "CMD", action = wezterm.action.IncreaseFontSize },
    { key = "-", mods = "CMD", action = wezterm.action.DecreaseFontSize },
    { key = "0", mods = "CMD", action = wezterm.action.ResetFontSize },
    { key = "h", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
    { key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
    { key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
    { key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
    { key = "h", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Left", 1 }) },
    { key = "j", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Down", 1 }) },
    { key = "k", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Up", 1 }) },
    { key = "l", mods = "CTRL|ALT", action = wezterm.action.AdjustPaneSize({ "Right", 1 }) },
    { key = "z", mods = "CTRL|SHIFT", action = wezterm.action.TogglePaneZoomState },
    { key = "x", mods = "CTRL|SHIFT", action = wezterm.action.ActivateCopyMode },
    { key = "h", mods = "CMD|CTRL|SHIFT", action = wezterm.action.SplitPane({ direction = "Left", size = { Percent = 50 } }) },
    { key = "j", mods = "CMD|CTRL|SHIFT", action = wezterm.action.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
    { key = "k", mods = "CMD|CTRL|SHIFT", action = wezterm.action.SplitPane({ direction = "Up", size = { Percent = 50 } }) },
    { key = "l", mods = "CMD|CTRL|SHIFT", action = wezterm.action.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
}
config.disable_default_key_bindings = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false
config.show_close_tab_button_in_tabs = false
config.tab_max_width = 64
config.inactive_pane_hsb = { brightness = 1.0, hue = 1.0, saturation = 1.0 }
config.animation_fps = 120
config.adjust_window_size_when_changing_font_size = false
config.status_update_interval = 200
config.max_fps = 120
config.enable_kitty_graphics = true

---@param pane PaneInformation
---@return string
wezterm.on("format-window-title", function(_, pane)
    return pane.title
end)

return config
