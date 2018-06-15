-- INIT -- {{{1
local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local naughty = require("naughty")
awful.client = require("awful.client")

local const = require("conky/common-constants")

-- luacheck: ignore dbus awesome

local dbus = dbus

-- DATA STRUCTURES -- {{{2

local function Set(t) -- {{{3
    local set = {}
    for _, value in pairs(t or {}) do
        set[value] = true
    end

    return {
        add = function(e)
            set[e] = true
        end,

        delete = function(e)
            set[e] = nil
        end,

        has = function(e)
            return set[e]
        end
    }
end

local function Stack() -- {{{3
    local stack = {}
    local head = 0
    return {
        head = function()
            return stack[head]
        end,

        push = function(e)
            head = head + 1
            stack[head] = e
        end,

        pop = function()
            if head == 0 then return nil end
            local e = stack[head]
            stack[head] = nil
            head = head - 1
            return e
        end
    }
end

-- MODULES -- {{{2

local widget = {  -- for the widget that awesome draws
-- two sets for 'reserving property names'
    -- for declaring subwidget properties
    -- passed down to child widgets
    SUBW_DECL = Set({ "conkybox", "iconbox", "labelbox", "background" }),
    -- for declaring the composed widgets
    -- not passed down to child widgets
    CONKY_DECL  = Set({
        "conky", "icon", "label", "updater", "buttons", "signals", "tooltip"
    }),
}

local window = {}  -- for conky's own window
local public = {   -- public interface
    config = {     -- canned widget configuration
        show_debug = { { "Control" }, 3 }
    },
    properties = {    -- client window properties
        floating = true,
        sticky = true,
        ontop = false,
        skip_taskbar = true,
        below = true,
        focusable = false,
        titlebars_enabled = false,
    }
}
local updater = {  -- for updating the widget
    ejected = {},
    conky_strings = {},
}

updater.debug = (function()
    local updates = {}
    local conky = {}
    local notification = nil
    local template = {
        title = "ConkyAwesome Debug",
        timeout = 0,
        destroy = function() notification = nil end
    }
    local function format(output, str1, str2)
        return output .. str1 .. " : " .. str2 .. "\n"
    end
    return {
        insert = function(str, i)
            updates[i] = str
        end,

        show_button = awful.button(
            public.config.show_debug[1],
            public.config.show_debug[2],
            function()
                notification = naughty.notify(template)
            end
        ),

        finish = function()
            if not notification then return end
            local output = ""
            for i, str in ipairs(updater.conky_strings) do
                output = format(output, str, (updates[i] or '<nil>'))
            end
            if #updater.ejected > 0 then
                output = output .. "== EJECTED WIDGETS ==\n"
                for _, pair in pairs(updater.ejected) do
                    output = format(output, pair[1], pair[2])
                end
            end
            naughty.replace_text(notification, template.title, output)
        end
    }
end)()

-- PUBLIC INTERFACE -- {{{1
function public.widget(root) -- {{{2
    -- builds the widget from nested tables
    local unprocessed = Stack()
    local processed   = Stack()
    local seen        = Set()

    unprocessed.push(widget.maybe_require(root))

    for raw_wibox in unprocessed.head do
        -- already processed or premade wibox: leaf
        if widget.already_built(raw_wibox) then
            processed.push(unprocessed.pop())

        -- not seen before, so mark, pass properties to children,
        -- and push children onto the unprocessed stack
        elseif not seen.has(raw_wibox) then
            seen.add(raw_wibox)
            for _, child in ipairs(raw_wibox) do
                child = widget.maybe_require(child)
                unprocessed.push(child)
                if not widget.already_built(child) then
                    widget.inherit_properties(child, raw_wibox)
                end
            end

        -- seen before, so all children are on the processed stack
        else
            -- make wibox and wrap in layout
            local layout = widget.make(raw_wibox)
            for _, _ in ipairs(raw_wibox) do
                layout:add(processed.pop())
            end
            -- pop raw and push processed
            unprocessed.pop()
            processed.push(layout)
        end
    end
    -- when unprocessed stack is empty
    -- finished wibox is single element on processed
    processed.head():buttons(updater.debug.show_button)
    return processed.pop()
end

function public.show_key(key, mod) -- {{{2
    -- sets the key to hold for the conky window to be visible
    return awful.key(mod or {}, key, window.raise, window.lower_delayed,
           { description = "conky window on top while held", group = "conky" })
end

function public.toggle_key(key, mod)  -- {{{2
    -- sets the key to press to toggle the conky window visibility
    return awful.key(mod or {}, key, window.toggle,
           { description = "toggle conky window on top", group = "conky" })
end

-- function public.mixin(...) {{{2
function public.mixin(...) --luacheck: no unused args
    local root = arg[#arg]
    for i = 1, #arg - 1 do
        root = require("conky/mixins/" .. arg[i])(root)
    end
    return root
end

function public.rules(rule) -- {{{2
    local rules = { rule = { class = public.class or "Conky" },
                    properties = public.properties }
    for k, v in pairs(rule or {}) do
        if k == "rule" then
            repeat until true
        elseif k == "properties" then
            for _k, _v in pairs(rule.properties) do
                print("setting prop '" .. _k .. '', _v)
                rules.properties[_k] = _v
            end
        else
            rules[k] = v
        end
    end
    return rules
end

-- WIDGET -- {{{1
function widget.make(raw) -- {{{2
    -- TODO:
    -- This thing has grown out of proportion
    --
    -- All the functions passing the composed widgets back as arguments
    -- should be rewritted to pass a single param object/table.
    --
    -- This will break user declarations, so it needs to test whether it receives
    -- a param object or the widgets as params. Write something that produces
    -- these functions
    local layout = wibox.layout.fixed.horizontal()

    local iconbox = nil
    if raw.icon then
        iconbox = wibox.widget.imagebox(raw.icon, true)
        widget.apply_properties(raw, iconbox, "iconbox")
        layout:add(iconbox)
    end

    local labelbox = nil
    if raw.label then
        labelbox = wibox.widget.textbox(raw.label)
        widget.apply_properties(raw, labelbox, "labelbox")
        layout:add(labelbox)
    end

    local background = nil
    if raw.background then
        background = wibox.container.background(layout)
        widget.apply_properties(raw, background, "background")
    end

    local conkybox = nil
    if raw.conky then
        conkybox = wibox.widget.textbox("")
        widget.apply_properties(raw, conkybox, "conkybox")
        layout:add(conkybox)

        updater.add_string(raw.conky)
        updater.add(conkybox, iconbox, labelbox, background, raw.updater)
    end

    local root
    if raw.background then
        root = wibox.layout.fixed.horizontal(background)
    else
        root = layout
    end

    if raw.buttons then
        local buttons = {}
        for _, button in ipairs(raw.buttons) do
            local mod = button[1]
            local button_num = button[2]
            local press = button[3]
            local release = button[4]
            local on_release

            if release then
                on_release = function()
                    release(conkybox, iconbox, labelbox, background)
                end
            end

            buttons = awful.util.table.join(buttons,
                awful.button(mod, button_num, function()
                    press(conkybox, iconbox, labelbox, background)
                end,
                on_release)
            )
        end
        root:buttons(buttons)
    end

    if raw.signals then
        for signal, func in pairs(raw.signals) do
            root:connect_signal(signal, function()
                func(conkybox, iconbox, labelbox, background)
            end)
        end
    end

    if raw.tooltip then
        awful.tooltip(awful.util.table.join(raw.tooltip, {
            objects = awful.util.table.join(raw.tooltip or {}, { root })
        }))
    end

    return root
end

function widget.inherit_properties(child, parent) -- {{{2
    for prop, value in pairs(parent) do
        -- assume all number keys are list items/nested widgets
        if type(prop) == "number" or widget.CONKY_DECL.has(prop) then
            repeat until true -- noop/continue
        -- parent supplies a table of properties for a composed widget
        elseif widget.SUBW_DECL.has(prop) then
            if child[prop] then
                widget.inherit_properties(child[prop], value)
            else
                child[prop] = value
            end
        else
            child[prop] = child[prop] or value
        end
    end
end

function widget.apply_properties(raw, w, wtype) -- {{{2
    -- applies the properties in the raw table to the widget w
    local props = {}
    for prop, value in pairs(raw) do
        -- skip the keys that we know are not widget properties
        if type(prop) == "number" or
           widget.SUBW_DECL.has(prop) or
           widget.CONKY_DECL.has(prop) then
            repeat until true
        else
            -- collect the common properties
            props[prop] = value
        end
    end

    for prop, value in pairs(raw[wtype] or {}) do
        -- collect properties specific to a composed widget
        props[prop] = value
    end

    for prop, value in pairs(props) do
        w[prop] = value
    end
end


function widget.maybe_require(t_or_str) -- {{{2
    if type(t_or_str) == "string" then
        local settings = public.config[t_or_str] or {}
        t_or_str = require("conky/widgets/" .. t_or_str)(settings)
    end
    return t_or_str
end

function widget.already_built(w) -- {{{2
    -- check for the _private table to determine if we're dealing with
    -- an already built widget or a layout
    return w._private
end

-- WINDOW -- {{{1
function window.toggle() -- {{{2
    local c = window.client()
    c.below = not c.below
    c.ontop = not c.ontop
    if c.ontop and public.raise then
        public.raise(c)
    elseif c.below and public.lower then
        public.lower(c)
    end
end

function window.raise() -- {{{2
    local c = window.client()
    c.below = false
    c.ontop = true
    if public.raise == nil then return end
    public.raise(c)
end

function window.lower() -- {{{2
    local c = window.client()
    c.ontop = false
    c.below = true
    if public.lower == nil then return end
    public.lower(c)
end

-- function window.lower_auto() -- {{{2
window.timer = gears.timer({ timeout = 0.05 })
window.timer:connect_signal("timeout", function()
    window.timer:stop()
    window.lower()
end)

function window.lower_delayed() -- {{{2
    window.timer:again()
end

function window.apply_properties(callback) -- {{{2
    local c = window.client()
    if not c.valid then return false end
    for prop, value in pairs(public.properties) do
        c[prop] = value
    end
    if callback then return callback(c) end
    return true
end

-- conky client autostart {{{2
awesome.connect_signal("startup",
                       function()
                           return window.apply_properties() or window.spawn()
                       end)

function window.spawn() -- {{{2
    if public.options then
        awful.spawn.with_shell(const("CONKY_LAUNCH") .. " " .. public.options)
    else
        awful.spawn(const("CONKY_LAUNCH"))
    end
end

function window.client() -- {{{2
    -- finds and returns the client object
    if window.c and window.c.valid then
        return window.c
    end

    window.c = awful.client.iterate(function(c)
                                        return c.class == (public.class or "Conky")
                                    end)()
    return window.c or {}
end

-- UPDATER -- {{{1
-- function updater.handle_update() -- {{{2
if dbus then
    dbus.add_match("session",
        "type='signal', interface='" .. const("UPDATE_FOR_WIDGET") .. "'")

    dbus.connect_signal(const("UPDATE_FOR_WIDGET"),

        (function()
            local all_but_delim = "([^" .. const("DELIMITER") .. "]*)(" ..
                                           const("DELIMITER") .. "?)"
            local widget_update = const("MEMBER")
            local need_string = const("CONKY_NEEDS_STRING")

            return function(data, conky_update)
                if data.member == widget_update then
                    -- conky sent a string

                                            -- lua "split string"
                    local from_conky_iter = string.gmatch(conky_update, all_but_delim)
                    for i, update_func in ipairs(updater) do
                        local update = from_conky_iter()

                        local success, err = pcall(update_func, update)
                        if not success then
                            if type(err) == 'string' then
                                updater.eject(i, 'Widget threw an error: '..err)
                            else
                                updater.eject(i, 'Widget threw an error')
                            end
                        end
                        -- update_func(update)
                        updater.debug.insert(update, i)
                    end
                    updater.debug.finish()
                elseif data.member == need_string then
                    -- conky is running but doesn't know what to send
                    updater.send_string()
                end
            end
        end)()
    )
else
    error("No DBus!")
end


function updater.send_string() -- {{{2
    dbus.emit_signal("session",
                     const("DBUS_PATH"),
                     const("STRING_FOR_CONKY"),
                     const("MEMBER"),
                     "string", updater.string)
end

function updater.add(conkybox, iconbox, labelbox, background, func) -- {{{2
    -- make an updater function and add to the list
    table.insert(updater, (function()
        -- luacheck: ignore
        local conkybox = conkybox
        local iconbox = iconbox
        local labelbox = labelbox
        local background = background
        local func = func or    function(result, conky, icon, label, background)
                                    conky:set_text(result or "")
                                end
        local last_update = nil

        return function(conky_result)
            if conky_result == last_update then return end
            func(conky_result, conkybox, iconbox, labelbox, background)
            last_update = conky_result
        end
    end)())
end

function updater.add_string(conkystr) -- {{{2
    table.insert(updater.conky_strings, conkystr)
    if updater.string then
        updater.string = updater.string .. const("DELIMITER") .. conkystr
    else
        updater.string = conkystr
    end
end

updater.eject = (function() -- {{{2
    local null_widget = function() end
    return function(i, reason)
        if updater[i] == null_widget then return end
        table.insert(updater.ejected, { updater.conky_strings[i], reason })
        updater[i] = null_widget
        naughty.notify({
            title = "ConkyAwesome",
            text = "A widget was ejected:\n" ..
                   updater.conky_strings[i] .. "\n" ..
                   "Reason: " .. reason,
            preset = naughty.config.presets.critical
        })
    end
end)()


return public --- {{{1
