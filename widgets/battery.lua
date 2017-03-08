local beautiful = require("beautiful")
local naughty = require("naughty")
local awful = require("awful")

local settings = {
    suspend_time = 300,
    suspend_cmd = "sudo /usr/sbin/pm-suspend-hybrid",
}

local function htime(seconds)
    local hours = math.floor(tonumber(seconds) / 3600)
    return string.format("%d:%02d", hours, (seconds - (3600 * hours)) / 60)
end

local function round(perc)
    return string.format("%03d", math.floor(string.sub(perc, 1, -2) / 20) * 20)
end

local suspend_initiated = false

local function suspend()
    if suspend_initiated then
        awful.spawn(settings.suspend_cmd)
    end
end

local function maybe_suspend(time_left)
    if suspend_initiated or time_left > settings.suspend_time then
        return
    end

    suspend_initiated = true
    naughty.notify({
        title = "Battery Empty!",
        text = "Suspending to disk in 1 minute.\n\n" ..
               "Attach power to cancel.\n\n" ..
               "Close this notification to suspend immediately",
        timeout = 60,
        destroy = suspend
    })
end

local current_icon = nil

return function(user_settings)
    for k,v in pairs(user_settings) do
        settings[k] = v
    end

    return {
        icon = beautiful["icon-battery-caution"],
        conky = "${battery_short} ${battery_time}",
        conkybox = { forced_width = 30, align = "center" },
        updater = function(update, textbox, iconbox, _)

            local iter = string.gmatch(update, "%S+")
            local state, perc, seconds = iter(), iter(), iter()

            local icon = "icon-battery-"
            local vis = false
            local time = nil

            if state == "F" then       -- full
                icon = icon .. "100-charging"
                suspend_initiated = false
            elseif state == "E" then   -- empty
                icon = icon .. "000"
                maybe_suspend(seconds)
            elseif state == "D" then   -- discharging
                vis = true
                time = htime(seconds)
                icon = icon .. round(perc)
                maybe_suspend(seconds)
            elseif state == "C" then   -- charging
                vis = true
                suspend_initiated = false
                time = htime(seconds)
                icon = icon .. round(perc) .. "-charging"
            else
                icon = icon .. "caution"
            end

            if time then textbox:set_text(time) end
            textbox.visible = vis
            if icon ~= current_icon then
                iconbox:set_image(beautiful[icon] or beautiful["icon-battery-caution"])
                current_icon = icon
            end
        end
    }
end
