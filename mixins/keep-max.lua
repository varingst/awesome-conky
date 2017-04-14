-- usage {{{1
--[[

This mixin provides an update function that:
    - Splits the update on spaces, and finds the highest value
    - Displays the current highest and (optionally) historically highest value
    - Clicking the widget resets and toggles the historical max being displayed

Widget declaration with the extra options:

conky.mixin("keep-max", {
    <usual widget declaration>

    show_max = false,                -- don't display max by default
    format = "%s°",                  -- format for conkybox without max
    max_format = "%s(%s)°",          -- format for conkybox with max
    conkybox = {
        forced_width = 40,           -- width when not showing max
        max_forced_width = 60,       -- width when showing max
        align = "center",
    }
}),

--]]

-- constructor {{{1
return function(raw_widget)
    -- init {{{2
    local defaults = {
        show_max = false,
        max_format = "%s(%s)°",
        format = "%s°",
        conkybox = {
            forced_width = 40,
            max_forced_width = 60,
            align = "center",
        }
    }

    local raw = raw_widget

    for k, v in pairs(defaults) do
        if k == "conkybox" then
            if raw.conkybox == nil then raw.conkybox = {} end
            for _k, _v in pairs(v) do
                raw.conkybox[_k] = raw.conkybox[_k] or _v
            end
        else
            raw[k] = raw[k] or v
        end
    end

    local max = 0
    local last_update = nil

    local show_max = raw.show_max
    local forced_width = raw.conkybox.forced_width
    local max_forced_width = raw.conkybox.max_forced_width

    if show_max then
        raw.conkybox.forced_width = max_forced_width
    end

    -- widget updater {{{2
    local function updater(update, textbox, _)
        last_update = update
        local current_max = 0
        for value in string.gmatch(update, "%S+") do
            local num = tonumber(value) or 0
            if num > current_max then
                current_max = num
            end
        end

        if current_max > max then
            max = current_max
        end

        if show_max then
            textbox:set_text(string.format(defaults.max_format, current_max, max))
        else
            textbox:set_text(string.format(defaults.format, current_max))
        end
    end

    -- toggle function for button binding {{{2
    local function toggle(conkybox, _)
        max = 0
        show_max = not show_max
        if show_max then
            conkybox:set_forced_width(max_forced_width)
        else
            conkybox:set_forced_width(forced_width)
        end
        updater(last_update, conkybox)
    end

    -- update raw widget {{{2

    raw.updater = updater
    raw.buttons = {
        { { }, 1, toggle },
    }

    return raw
end
