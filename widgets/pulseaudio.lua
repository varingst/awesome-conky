-- usage {{{1
--[[

Requirements:
 - Battery icons in theme:
    - beautiful["icon-pulseaudio-V"] = <filename>
      where V is max, med, min, 0 and muted

Configuration in rc.lua, here shown with the default settings:

local conky = require("conky")
conky.config.pulseaudio = {
    sink = 0,                  the sink to target
    step = 10,                 volume percentage to increment/decrement
    launch = "pavucontrol"     util to launch on right click
    slider = {                 configuration of the slider appearance, see:
        forced_width = 50,       awesomewm.org/apidoc/wibox.widget.slider.html
        handle_width = 3,
        bar_height = 3,
    },
}
--]]


-- init {{{1
local awful = require("awful")
local wibox = require("wibox")
local util = require("conky/util")

local settings = {
    sink = 0,
    step = 10,
    launch = "pavucontrol",
    slider = {},
}

local slider_defaults = {
    value = 50,
    forced_width = 50,
    handle_width = 3,
    bar_height = 3,
}

local slider_immutable = {
    minimum = 0,
    maximum = 100,
    visible = false,
    widget = wibox.widget.slider,
}

local function setter_for(sink) -- {{{1
    local cmd = "pactl set-sink-mute " .. sink .. " false;" ..
                "pactl set-sink-volume " .. sink .. " "
    return function(perc)
        awful.spawn.with_shell(cmd .. perc .. "%")
    end
end

local function mute_toggle_for(sink) -- {{{1
    local cmd = "pactl set-sink-mute " .. sink .. " toggle"
    return function()
        awful.spawn.with_shell(cmd)
    end
end

-- widget constructor {{{1
return function(user_settings)
    for k,v in pairs(user_settings) do
        settings[k] = v
    end

    local slider = wibox.widget(awful.util.table.join(
                        slider_defaults,
                        settings.slider,
                        slider_immutable))

    local get_icon = util.icon_for("icon-pulseaudio-", "icon-pulseaudio-muted")
    local current_icon = nil
    local current_volume = 0
    local muted = false
    local set_volume = setter_for(settings.sink)
    local mute_toggle = mute_toggle_for(settings.sink)

    local updater = function(update, _, iconbox, _)
        local icon = nil
        local volume = tonumber(update) or 0
        if volume < 0 then
            muted = true
            volume = volume * -1
        else
            muted = false
        end

        if muted then
            icon = "muted"
        elseif volume == 0 then
            icon = "0"
        elseif volume < 33 then
            icon = "min"
        elseif volume < 66 then
            icon = "med"
        else
            icon = "max"
        end

        if volume ~= current_volume then
            slider.value = volume
            current_volume = volume
        end

        if icon ~= current_icon then
            iconbox:set_image(get_icon(icon))
            current_icon = icon
        end

    end

    return {
        slider,
        {
            icon = get_icon("med"),
            conky    = "${exec pactl list sinks | " ..
                       util.awk("pulseaudio-sink", { sink = settings.sink }) .. "}",
            conkybox = { visible = false },

            signals = {
                ['mouse::enter'] = function() slider.visible = true end,
                ['mouse::leave'] = function() slider.visible = false end
            },

            buttons = {
                { {}, 1, function(_, iconbox, _)
                    mute_toggle()
                    muted = not muted
                    updater("" .. slider.value, nil, iconbox)
                end },
                { {}, 3, function()
                    awful.spawn(settings.launch)
                end },
                { {}, 4, function(_, iconbox, _)
                    local new = slider.value + settings.step
                    if new > slider.maximum then
                        slider.value = slider.maximum
                    else
                        slider.value = new
                    end
                    set_volume(slider.value)
                    updater("" .. slider.value, nil, iconbox)
                end },
                { {}, 5, function(_, iconbox, _)
                    local new = slider.value - settings.step
                    if new < slider.minimum then
                        slider.value = slider.minimum
                    else
                        slider.value = new
                    end
                    set_volume(slider.value)
                    updater("" .. slider.value, nil, iconbox)
                end },
            },
            updater = updater,
        }
    }
end
