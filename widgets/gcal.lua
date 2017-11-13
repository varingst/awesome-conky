-- usage {{{1
--[[

Requirements:
    gcal       - GNU cal replacement

Configuration in rc.lua, here shown with the default settings:

local conky = require("conky")
conky.config.gcal = {
    time_format = "%R",           -- format for the clock, to pass to conky ${time}
    fixed_width = 30,             -- fixed width for the clock widget
    clock_font = "Monospace 10"   -- font for the clock widget
    strip = function(cal_str)     -- function to apply to the output from gcal
                                  -- the default strips emtpy lines
    gcal_args = "."               -- arguments to gcal, the default shows 3 months
                                  -- see gcal --usage --pager
    markup = {
        calendar = "font='Monospace 10'",       -- markup for the calendar tooltip text
        today = "foreground='green'",           -- markup for highlighting the current day
        holiday = "foreground='red'",           -- markup for highlighting holidays
                                                -- (requires providing a
                                                --  --cc-holidays=? argument to gcal)
    },
    tooltip = {                           -- table to pass to awful.tooltip()
        mode = "outside",                 -- show calendar tooltip below
        preferred_positions = "bottom",   -- the clock widget
    }

}

--]]

-- init {{{1
local awful = require('awful')

local settings = {
    time_format = "%R",
    fixed_width = 30,
    clock_font = "Monospace 10",
    strip = function(cal_str) return cal_str:gsub("^\n+", ""):gsub("\n+", "\n") end,
    gcal_args = ".",
    markup = {
        calendar = "font='Monospace 10'",
        today = "foreground='green'",
        holiday = "foreground='red'",
    },
    tooltip = {}
}

local gcal_cmd = "/usr/bin/gcal --highlighting=\" :}: :]\" "

local function span(attr, str)
    local open = "<span " .. attr .. ">"
    local close = "</span>"
    if str then
        return open .. str .. close
    else
        return open, close
    end
end

local function errormsg(msg)
    print(msg)
    return span("foreground='red'", msg)
end

local function wrap(markup)
    local open, close = span(markup)
    return open .. "%1" .. close .. " "
end

local tooltip = {
    default = {
        mode = "outside",
        preferred_positions = { "bottom" },
    },
    immutable = {
        timer_function = function()
            local handle, err = io.popen(gcal_cmd .. settings.gcal_args)
            if handle then

                local ok, result = pcall(function() return handle:read("*a") end)
                handle:close()

                if ok then
                    return span(settings.markup.calendar,
                                settings.strip(result):gsub(
                       "(%d+)}", wrap(settings.markup.today)):gsub(
                       "(%d+)]", wrap(settings.markup.holiday)))
                else
                    return errormsg("handle:read error reading from gcal: " ..
                                    (handle or "nil"))
                end
            else
                return errormsg("popen error reading from gcal: " ..
                                (err or "nil"))
            end
        end
    }
}

-- widget constructor {{{1
return function(user_settings)
    for k,v in pairs(user_settings) do
        if k == "markup" then
            for _k, _v in pairs(v) do
                settings[k][_k] = _v
            end
        else
            settings[k] = v
        end
    end

    return {
        conky = "${time " .. settings.time_format .. "}",
        conkybox = {
            align = "center",
            fixed_width = settings.fixed_width,
            font = settings.clock_font
        },
        tooltip = awful.util.table.join(tooltip.default,
                                        settings.tooltip,
                                        tooltip.immutable)
    }
end
