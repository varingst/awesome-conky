-- INIT -- {{{1

local ldbus = require("ldbus")
local CONST = require("common-constants")
local dbus = {}

-- TODO: some actual error handling

function dbus.setup(name) -- {{{1
  -- returns a set of functions,
  -- one for emitting signals, and one for checking for them
  --
  -- NOTE: including this module returns this function
  if not (name == "conky" or name == "awesome") then
    print("Must be conky or awesome, got:", name)
    return
  end

  local conn = assert(ldbus.bus.get("session"))
  dbus.request_name(conn, name)

  if name == "conky" then
    return dbus.listener_for(conn, CONST("STRING_FOR_CONKY")),
           dbus.emitter_for(conn, CONST("UPDATE_FOR_WIDGET")),
           dbus.emitter_for(conn, CONST("UPDATE_FOR_WIDGET"), CONST("CONKY_NEEDS_STRING"))
  else
    return dbus.listener_for(conn, CONST("UPDATE_FOR_WIDGET")),
           dbus.emitter_for(conn, CONST("STRING_FOR_CONKY"))
  end
end

function dbus.listener_for(conn, signal_type) -- {{{1
  -- returns a function that checks if the specified signal has been emitted
  --local conn = conn
  assert(ldbus.bus.add_match(conn,
                             "type='signal', interface='" .. signal_type .. "'"))
  return function()
    if conn:read_write(0) then
      local msg = conn:pop_message()
      if msg and msg:get_member() == CONST("MEMBER") then
        local iter = ldbus.message.iter.new()
        msg:iter_init(iter)
        return iter:get_basic()
      end
    end
  end
end

function dbus.emitter_for(conn, signal_type, member) -- {{{1
  -- returns a function that emits the specified signal
  --local conn = conn
  --local signal_type = signal_type
  local last_message = nil

  return function(message)
    if message == last_message then return end

    local msg = assert(ldbus.message.new_signal(CONST("DBUS_PATH"),
                                                signal_type,
                                                member or CONST("MEMBER")),
                       "Message Null")
    local iter = ldbus.message.iter.new()
    msg:iter_init_append(iter)

    assert(iter:append_basic(message), "Out of Memory")

    -- local ok, serial = assert(conn:send(msg))
    assert(conn:send(msg))

    conn:flush()
    last_message = message
  end
end

function dbus.request_name(conn, name) -- {{{1
  -- register our bus name with dbus
  assert(assert(
    ldbus.bus.request_name(conn,
                           CONST(name:upper() .. "_NAME"),
                           { replace_existing = true }
    ) == "primary_owner"
  ), "Not Primary Owner")
end

return dbus.setup -- {{{1
