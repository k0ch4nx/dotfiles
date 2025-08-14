local M = {}

M.opt = {
    winborder = "rounded",
}

M.chars = {
    null = "",
    space = " ",
    box_drawings_light_vertical = "│",
    left_one_eighth_block = "▏",
}

M.nerd_fonts = {
    nf_cod_error = "",
    nf_cod_info = "",
    nf_cod_warning = "",
    nf_fa_circle = "",
    nf_fa_lock = "",
    nf_fa_times_circle = "",
    nf_md_close_circle_outline = "󰅚",
    nf_md_lightbulb_outline = "󰌶",
    nf_ple_lower_left_triangle = "",
    nf_ple_lower_right_triangle = "",
    nf_ple_upper_left_triangle = "",
    nf_ple_upper_right_triangle = "",
}

M.conditions = {
    is_linux = vim.fn.has("linux") == 1,
    is_mac = vim.fn.has("mac") == 1,
    is_windows = vim.fn.has("win32") == 1,
    is_headless = #vim.api.nvim_list_uis() == 0,
}

M.math = {
    i32_max = bit.bnot(bit.lshift(1, 31)),
}

M.table = {
    unique = function(...)
        local seen = {}
        local result = {}

        for _, list in ipairs({ ... }) do
            for _, v in ipairs(list) do
                if not seen[v] then
                    seen[v] = true
                    result[#result + 1] = v
                end
            end
        end

        return result
    end,
}

return M
