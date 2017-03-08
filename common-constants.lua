local COMMON_NAME = "org.awesomewm"
local CONKY_NAME = COMMON_NAME .. ".conky"
local AWESOME_NAME = COMMON_NAME .. ".awful"

local constants = {
    CONKY_LAUNCH          = "conky",
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


