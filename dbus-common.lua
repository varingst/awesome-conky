-- INIT -- {{{1

local ldbus = require("ldbus")
local CONST = require("common-constants")
local dbus = {}

local fnoop = function() end

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
  if not pcall(dbus.request_name(conn, name)) then
      return fnoop, fnoop, fnoop
  end

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
  if CONKY_DEBUG then
      print("setting up listener for signal: " .. signal_type)
  end
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

  if CONKY_DEBUG then
      print("setting up emitter on: " .. signal_type .. "." .. (member or CONST("MEMBER")))
  end

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
  local busname = CONST(name:upper() .. "_NAME")
  if CONKY_DEBUG then
      print("requesting name: " .. busname)
  end

  assert(assert(
    ldbus.bus.request_name(conn,
                           busname,
                           { replace_existing = true }
    ) == "primary_owner", "Could not acquire " .. busname
  ), "Not Primary Owner")
end

return dbus.setup -- {{{1
