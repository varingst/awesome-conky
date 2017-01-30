-- luacheck: globals CONKY_DEBUG
local COMMON_NAME = "org.awesomewm"
    --local COMMON_NAME = "org.naquadah.awesome"
local CONKY_NAME = COMMON_NAME .. ".conky"
local AWESOME_NAME = COMMON_NAME .. ".awful"

local HOME = os.getenv("HOME")

-- TODO: make this a bit for flexible
local CONKY_LAUNCH = HOME .. "/.config/awesome/conky/conky-awesome-launch"

if CONKY_DEBUG then
    CONKY_NAME = "org.awesomewm.test.conky"
    CONKY_LAUNCH = CONKY_LAUNCH .. " --debug"
end

-- todo: make this an option

local constants = {
    CONKY_LAUNCH          = CONKY_LAUNCH,
    DELIMITER             = "", -- <C-D>
    DBUS_PATH             = "/",
    CONKY_NAME            = CONKY_NAME,
    AWESOME_NAME          = AWESOME_NAME,
    STRING_FOR_CONKY      = CONKY_NAME .. ".StringForConky",
    UPDATE_FOR_WIDGET     = AWESOME_NAME .. ".UpdateForWidget",
    MEMBER                = "Conky",
    CONKY_NEEDS_STRING    = "Ikiteiruyo",
}

return function(const)
    return constants[const] or
        error("No constant '" .. const .. "' exists, typo?", 2)
end


