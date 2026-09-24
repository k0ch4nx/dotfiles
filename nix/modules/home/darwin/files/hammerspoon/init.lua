local function spaces_on_current_screen()
    local current = hs.spaces.focusedSpace()
    if not current then
        return nil
    end

    local screen_uuid = hs.spaces.spaceDisplay(current)
    if not screen_uuid then
        return nil
    end

    local ids = hs.spaces.spacesForScreen(screen_uuid)
    if not ids then
        return nil
    end

    for index, id in ipairs(ids) do
        if id == current then
            return ids, index
        end
    end

    return nil
end

local function move_space(offset)
    local ids, index = spaces_on_current_screen()
    if not ids then
        return
    end

    hs.spaces.gotoSpace(ids[((index - 1 + offset) % #ids) + 1])
end

local function move_to_space_number(number)
    local ids = spaces_on_current_screen()
    if ids and ids[number] then
        hs.spaces.gotoSpace(ids[number])
    end
end

local current_space = hs.spaces.focusedSpace()
local previous_space = nil

hs.spaces.watcher.new(function()
    local focused = hs.spaces.focusedSpace()
    if focused and focused ~= current_space then
        previous_space, current_space = current_space, focused
    end
end):start()

local function toggle_previous_space()
    local focused = hs.spaces.focusedSpace()
    if previous_space and previous_space ~= focused then
        hs.spaces.gotoSpace(previous_space)
    end
end

hs.hotkey.bind({ "alt" }, "tab", toggle_previous_space)
hs.hotkey.bind({ "alt" }, "p", function()
    move_space(-1)
end)
hs.hotkey.bind({ "alt" }, "n", function()
    move_space(1)
end)

for number, key in ipairs({ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }) do
    hs.hotkey.bind({ "alt" }, key, function()
        move_to_space_number(number)
    end)
end

hs.hotkey.bind({ "alt", "shift" }, "r", function()
    hs.task.new("/etc/profiles/per-user/k0ch4nx/bin/paneru", nil, { "restart" }):start()
end)
