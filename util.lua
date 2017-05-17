local beautiful = require("beautiful")
local public = {}

function public.awesome_root() -- {{{1
    --return "/home/loke/.config/awesome/" .. (file or "")
     return string.gsub(awesome.conffile, "[^/]*$", "")
end

function public.awk(file, args) -- {{{1
    local cmd = "awk"
    for a, v in pairs(args or {}) do
        cmd = cmd .. " -v " .. a .. "=" .. v
    end
    return cmd .. " -f " .. public.awesome_root() .. "conky/awk/" .. file .. ".awk"
end

function public.icon_for(prefix, fallback)
    return function(icon)
        return beautiful[prefix .. icon] or beautiful[fallback]
    end
end

return public
