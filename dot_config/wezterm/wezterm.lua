---@type Wezterm
local wezterm = require("wezterm")

local config = wezterm.config_builder()

local color_scheme = "Kanagawa (Gogh)"

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

config.font_size = 18
config.window_decorations = "TITLE|RESIZE|MACOS_USE_BACKGROUND_COLOR_AS_TITLEBAR_COLOR"
config.font = wezterm.font_with_fallback({
    "JetBrainsMono Nerd Font",
    "ヒラギノ丸ゴ ProN",
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

---@param s string
---@return string
local function basename(s)
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

---@param proc LocalProcessInfo
---@return string
local function proc_label(proc)
    if not proc then
        return ""
    end

    local exe = proc.executable
    if exe and exe ~= "" then
        return string.format("%d:%s", proc.pid, basename(exe))
    end
    local argv1 = proc.argv and proc.argv[1]
    if argv1 and argv1 ~= "" then
        return string.format("%d:%s", proc.pid, basename(argv1))
    end
    if proc.name and proc.name ~= "" then
        return string.format("%d:%s", proc.pid, proc.name)
    end
    return string.format("%d:?", proc.pid or 0)
end

---@param proc LocalProcessInfo?
---@return string
local function render_proc_tree(proc)
    if not proc then
        return ""
    end

    local label = proc_label(proc)
    local children = proc.children
    if not (children and next(children)) then
        return label
    end

    local list = {}
    for _, child in pairs(children) do
        table.insert(list, child)
    end
    table.sort(list, function(a, b)
        return (a.pid or 0) < (b.pid or 0)
    end)

    local parts = {}
    for _, child in ipairs(list) do
        local t = render_proc_tree(child)
        if t ~= "" then
            table.insert(parts, t)
        end
    end

    if #parts == 0 then
        return label
    end
    if #parts == 1 then
        return string.format("%s -> %s", label, parts[1])
    end
    return string.format("%s -> [%s]", label, table.concat(parts, ", "))
end

---@param pane Pane
---@return string
local function build_window_title(pane)
    local proc_info = pane:get_foreground_process_info()
    local proc_tree = render_proc_tree(proc_info)
    return string.format("%s │ %s", pane:get_title(), proc_tree)
end

wezterm.on("update-status", function(window, pane)
    window:mux_window():set_title(build_window_title(pane))
end)

---@param tab TabInformation
---@param pane PaneInformation
---@param tabs TabInformation[]
---@param panes PaneInformation[]
---@param cfg Config
---@return string
wezterm.on("format-window-title", function(tab, pane, tabs, panes, cfg)
    return build_window_title(wezterm.mux.get_pane(pane.pane_id))
end)

return config
