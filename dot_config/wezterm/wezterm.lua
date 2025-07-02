---@type Wezterm
local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Kanagawa (Gogh)"
config.adjust_window_size_when_changing_font_size = false
config.animation_fps = 120
config.colors = { ---@diagnostic disable-line: missing-fields
    tab_bar = {
        background = "NONE",
    },
}
config.font = wezterm.font_with_fallback({
    "JetBrainsMono Nerd Font",
    "ヒラギノ丸ゴ ProN",
})
config.font_size = 14
config.front_end = "OpenGL"
config.max_fps = 120
config.show_close_tab_button_in_tabs = false ---@diagnostic disable-line: inject-field
config.show_new_tab_button_in_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE"

config.keys = {
    {
        key = "t",
        mods = "CMD",
        ---@diagnostic disable-next-line: assign-type-mismatch
        action = wezterm.action.SpawnCommandInNewTab({
            cwd = wezterm.home_dir,
        }),
    },
}

local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
tabline.setup({
    options = {
        theme = config.color_scheme,
        tabs_enabled = true,
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

return config
