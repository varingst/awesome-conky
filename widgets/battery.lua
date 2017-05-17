-- usage {{{1
--[[

Requirements:
 - Conky running with times_in_seconds = true
 - Battery icons in theme:
    - beautiful["icon-battery-caution"] = <filename> for errors and unknowns
    - beautiful["icon-battery-N"]
      where N is 000, 020, 040, 060, 080, 100
      when the battery is draining
    - beautiful["icon-battery-N-charging"]
      where N is 000, 020, 040, 060, 080, 100
      when the battery is charging

Configuration in rc.lua, here shown with the default settings:

local conky = require("conky")
conky.config.battery = {
    suspend_time = 300,
    suspend_cmd = "sudo /usr/sbin/pm-suspend-hybrid"
}

suspend_time is the time left on the battery in seconds when the suspend
notification is shown. Account for the 60 seconds the notification is
displayed before actually suspending the system.

--]]

-- init {{{1
local beautiful = require("beautiful")
local naughty = require("naughty")
local awful = require("awful")
local util = require("conky/util")

local suspend_notification = nil
local suspend_initiated = false
local settings = {
    suspend_time = 300,
    suspend_cmd = "sudo /usr/sbin/pm-suspend-hybrid",
}

local function htime(seconds) -- {{{1
    local hours = math.floor(tonumber(seconds) / 3600)
    return string.format("%d:%02d", hours, (seconds - (3600 * hours)) / 60)
end

local function round(perc) -- {{{1
    return string.format("%03d", math.floor(string.sub(perc, 1, -2) / 20) * 20)
end

local function suspend() -- {{{1
    if suspend_initiated then
        awful.spawn(settings.suspend_cmd)
    end
    suspend_notification = nil
end

local function maybe_suspend(time_left) -- {{{1
    if suspend_initiated or tonumber(time_left) > settings.suspend_time then
        return
    end

    suspend_initiated = true
    suspend_notification = naughty.notify({
        title = "Battery Empty!",
        text = "Suspending to disk in 1 minute.\n\n" ..
               "Attach power to cancel.\n\n" ..
               "Click this notification to suspend immediately",
        timeout = 60,
        fg = beautiful.fg_urgent,
        bg = beautiful.bg_urgent,
        destroy = suspend,
    })
end

local function maybe_cancel_suspend() -- {{{1
    if not suspend_initiated or suspend_notification == nil then
        return
    end
    suspend_initiated = false
    suspend_notification.die(naughty.notificationClosedReason.dismissedByUser)
end

-- widget constructor {{{1
return function(user_settings)
    for k,v in pairs(user_settings) do
        settings[k] = v
    end

    local current_icon = nil
    local get_icon = util.icon_for("icon-battery-", "icon-battery-caution")

    return {
        icon = get_icon("caution"),
        conky = "${battery_short} ${battery_time}",
        conkybox = { forced_width = 30, align = "center" },
        updater = function(update, textbox, iconbox, _)

            local iter = string.gmatch(update, "%S+")
            local state, perc, seconds = iter(), iter(), iter()

            local icon = nil
            local vis = false
            local time = nil

            if state == "F" then       -- full
                icon = "100-charging"
                maybe_cancel_suspend()
            elseif state == "E" then   -- empty
                icon = "000"
                maybe_suspend(seconds)
            elseif state == "D" then   -- discharging
                vis = true
                time = htime(seconds)
                icon = round(perc)
                maybe_suspend(seconds)
            elseif state == "C" then   -- charging
                vis = true
                maybe_cancel_suspend()
                time = htime(seconds)
                icon = round(perc) .. "-charging"
            else
                icon = "caution"
            end

            if time then textbox:set_text(time) end
            textbox.visible = vis
            if icon ~= current_icon then
                iconbox:set_image(get_icon(icon))
                current_icon = icon
            end
        end
    }
end
