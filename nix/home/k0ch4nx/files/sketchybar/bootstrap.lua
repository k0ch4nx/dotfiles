local NAME = "sketchybar"

local function join(...)
    return table.concat({ ... }, "/")
end

local function exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local CONFIG_DIR = join(os.getenv("XDG_CONFIG_HOME"), NAME)
local CACHE_DIR = join(os.getenv("XDG_CACHE_HOME"), NAME)
local MODULES_DIR = join(CONFIG_DIR, "modules")
local SO_PATH = join(MODULES_DIR, NAME .. ".so")

local function build()
    local repo_dir = join(CACHE_DIR, "SbarLua")

    os.execute(table.concat({
        "set -euxo pipefail",
        ("[ -d %s ] && (cd %s && git pull) || git clone https://github.com/FelixKratz/SbarLua.git %s"):format(repo_dir, repo_dir, repo_dir),
        ("INSTALL_DIR=%s make -eC %s install"):format(MODULES_DIR, repo_dir),
    }, " && "))
end

if not exists(SO_PATH) then
    build()
end
