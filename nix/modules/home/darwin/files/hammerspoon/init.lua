-- macOS 27 moved Mission Control's accessibility tree from the Dock process to
-- com.apple.WindowManager, which breaks hs.spaces.gotoSpace ("unable to get
-- Mission Control data from the Dock"). Try the WindowManager tree first, then
-- fall back to the stock implementation. Revisit when Hammerspoon ships a fix.
local function installSpacesCompat()
    local axuielement = require("hs.axuielement")
    local application = require("hs.application")
    local host = require("hs.host")
    local spaces = require("hs.spaces")
    local timer = require("hs.timer")

    local version = host.operatingSystemVersion()
    if not version or version.major < 27 then
        return
    end

    local original = spaces.gotoSpace

    local function findById(root, id, depth)
        for _, element in ipairs(root) do
            if element.AXIdentifier == id then
                return element
            end
            if depth > 0 then
                local found = findById(element, id, depth - 1)
                if found then
                    return found
                end
            end
        end
        return nil
    end

    local function spacesList()
        for _, running in ipairs(application.runningApplications()) do
            if tostring(running:name() or "") == "WindowManager" then
                return findById(axuielement.applicationElement(running), "mc.spaces.list", 4)
            end
        end
        return nil
    end

    spaces.gotoSpace = function(spaceID)
        local display = spaces.spaceDisplay(spaceID)
        if not display then
            return nil, "space not found in managed displays"
        end
        local ids = spaces.spacesForScreen(display)
        if not ids then
            return nil, "no spaces for display"
        end
        local count
        for index, id in ipairs(ids) do
            if id == spaceID then
                count = index
                break
            end
        end
        if not count then
            return nil, "space not in managed display list"
        end

        local opened = false
        if not spacesList() then
            spaces.toggleMissionControl()
            opened = true
        end

        local list, deadline = nil, timer.secondsSinceEpoch() + 2
        while not list and timer.secondsSinceEpoch() < deadline do
            list = spacesList()
            if not list then
                timer.usleep(50000)
            end
        end
        if not list then
            if opened then
                spaces.toggleMissionControl()
            end
            return original(spaceID)
        end

        local buttons = {}
        for _, button in ipairs(list) do
            buttons[#buttons + 1] = button
        end
        local target = buttons[count]
        if not target then
            if opened then
                spaces.toggleMissionControl()
            end
            return original(spaceID)
        end
        local ok, err = target:performAction("AXPress")
        if ok then
            return true
        end
        if opened then
            spaces.toggleMissionControl()
        end
        return original(spaceID)
    end
end

installSpacesCompat()

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
        print("move_space: no spaces found for the current screen")
        return
    end

    local ok, err = hs.spaces.gotoSpace(ids[((index - 1 + offset) % #ids) + 1])
    if not ok then
        print("move_space: gotoSpace failed: " .. tostring(err))
    end
end

local function move_to_space_number(number)
    local ids = spaces_on_current_screen()
    if not ids or not ids[number] then
        print("move_to_space_number: no space at index " .. tostring(number))
        return
    end

    local ok, err = hs.spaces.gotoSpace(ids[number])
    if not ok then
        print("move_to_space_number: gotoSpace failed: " .. tostring(err))
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
