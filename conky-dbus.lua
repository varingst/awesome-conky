
local listen, send, need_string = require("dbus-common")("conky")

local conky_string = nil
local previous_request = 0

-- luacheck:ignore conky_parse

function conky_update_awesome() -- luacheck: ignore
    conky_string = listen() or conky_string

    if conky_string then
        send(conky_parse(conky_string))
    elseif os.time() > previous_request + 10 then
        need_string("pretty please")
        previous_request = os.time()
    end
end
