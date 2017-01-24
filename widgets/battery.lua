local beautiful = require("beautiful")

local function htime(seconds)
    local hours = math.floor(tonumber(seconds) / 3600)
    return string.format("%d:%02d", hours, (seconds - (3600 * hours)) / 60)
end

local function round(perc)
    return string.format("%03d", math.floor(string.sub(perc, 1, -2) / 20) * 20)
end

local current_icon = nil

return {
    icon = beautiful["icon-battery-caution"],
    conky = "${battery_short} ${battery_time}",
    conkybox = { forced_width = 30, align = "center" },
    updater = function(update, textbox, iconbox, _)

        local iter = string.gmatch(update, "%S+")
        local state, perc, seconds = iter(), iter(), iter()

        -- print("u:", update)
        -- print("s:", state)
        -- print("%:", perc)
        -- print("sec:", seconds)

        local icon = "icon-battery-"
        local vis = false
        local time = nil

        if state == "F" then       -- full
            icon = icon .. "100-charging"
        elseif state == "E" then   -- empty
            icon = icon .. "000"
        elseif state == "D" then   -- discharging
            vis = true
            time = htime(seconds)
            icon = icon .. round(perc)
        elseif state == "C" then   -- charging
            vis = true
            time = htime(seconds)
            icon = icon .. round(perc) .. "-charging"
        else
            icon = icon .. "caution"
        end

        -- print("text:", t)
        -- print("icon:", i)

        if time then textbox:set_text(time) end
        textbox.visible = vis
        if icon ~= current_icon then
            iconbox:set_image(beautiful[icon] or beautiful["icon-battery-caution"])
            current_icon = icon
        end
    end
}
