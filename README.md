# Conky widgets for Awesome WM 4

`conky-awesome` is a framework for making [awesome](https://awesomewm.org) widgets displaying system information from [conky](https://github.com/brndnmtthws/conky)

`conky-awesome` provides some optional keybindings to manange conky's own
X-window, but you can also run `conky-awesome` headless by configuring conky
with `out_to_x = false` and only have it update your widgets.

## Requirements
* conky
* awesome with dbus support
* [lua bindings to dbus](https://github.com/daurnimator/ldbus)

## Installation
Clone this repo to `~/.config/awesome/conky`

## Configuration

### conkyrc

```
conky.config = {
    .....
    lua_load = "~/.config/awesome/conky/conky-dbus.lua",
    lua_draw_hook_pre = "conky_update_awesome",
}
```

### rc.lua

```
local conky = require("conky")
```

This is all that is required to have conky start at launch.
Restarting awesome will not spawn additional conky clients.

To launch conky with custom options, i.e. a different `conkyrc`:

```
conky.options = "-c ~/.conky/my_special_conkyrc"
```

#### Keybindings

The conky client's own window defaults to being behind all other windows.

Bind keys for raising the client window on top.

```
globalkeys = awful.util.table.join(
    awful.key( .....
    .....
    conky.show_key("F12"),                -- conky window on top while held
    conky.toggle_key("F12"), { modkey })  -- toggle conky on top
)
```
Both functions have this signature:
`(keystring, [ modifier table ])`

You can also provide functions to call when the window is raised and lowered

```
conky.raise = function(c) c.opacity = 1.0 end
conky.lower = function(c) c.opacity = 0.4 end
````

If you are running conky with a non-standard window class, by setting
`own_window_class` in `conkyrc`, you must also set this in `rc.lua` for
the keybindings to work:

```
conky.class = "MyClass"
```

#### Client Window Properties

To set [properties](https://awesomewm.org/apidoc/classes/client.html#Object_properties) for the client window (defaults shown):
```
conky.properties = {
    floating = true,
    sticky = true,
    ontop = false,
    skip_taskbar = true,
    below = true,
    focusable = true,
    titlebars_enabled = false,
}
```

For these properties to apply properly when awesome is started and restarted,
the following must be added to the `Rules` section in `awesome/rc.lua`:

```
awful.rules.rules = {
    ....
    conky.rules()
}
```

Extra properties may be provided to be applied on launch, as per [awful.rules](https://awesomewm.org/apidoc/libraries/awful.rules.html):
```
awful.rules.rules = {
    ....
    conky.rules({ properties = { tag = "3" }, callback = function(c) ... end })
}
```

## Making Conky Widgets

Conky widget declaration:
```
{
  icon             = <string>,     -- image filename
  label            = <string>,     -- text for a label
  conky            = <string>,     -- the string conky evaluates with conky_parse()
  background       = <table>,      -- background properties table
  updater          = <function>,   -- custom updater function
  buttons          = <table>,      -- buttons to connect to the widget
  signals          = <table>,      -- signals to connect to the widget
  tooltip          = <table>,      -- tooltip for the widget
  <wibox property> = <value>       -- properties for the widgets
  {                          -- any number of child widgets:
    <conky declaration>,     -- nested conky widget declarations
    <canned conky widget>,   -- premade widgets from .config/awesome/conky/widgets
    <any widget>             -- to place other widgets in-between conky widgets
  }
}
```

A conky widget consists of up to four subwidgets, all optional:
  - `icon` declares a [wibox.widget.imagebox](http://awesomewm.org/apidoc/classes/wibox.widget.imagebox.html) instance
  - `label` declares a [wibox.widget.textbox](http://awesomewm.org/apidoc/classes/wibox.widget.textbox.html) instance
  - `conky` declares a [wibox.widget.textbox](http://awesomewm.org/apidoc/classes/wibox.widget.textbox.html) instance
  - `background` declares a [wibox.container.background](http://awesomewm.org/apidoc/classes/wibox.container.background.html) instance

### A minimal widget

Simply declaring a string to be evaluated by conky:
```
s.mywibox:setup {
  .....
  conky.widget({ conky = "CPU: ${cpu}% MEM: ${memperc}% GPU: ${hwmon 0 temp 1}" }),
  ....
}
```

### Icons and labels

Simple example with an icon and a text label:
```
conky.widget({
    icon = "my_neat_cpu_icon.png",
    label = "CPU:",
    conky = "${cpu}"
})

```

### Subwidgets

Setting wibox properties individually for subwidgets:

```
conky.widget({
  label = "CPU:",
  conky = "${cpu}",

  -- properties for the background wibox
  background = { bg = "red" },

  -- properties for the label wibox
  labelbox = { font = "Font for Label" },

  -- properties for the conky wibox
  conkybox = { force_width = 30, align = "right" },

  -- properties for the icon wibox
  iconbox = { opacity = 0.8 },
})
```

### Child widgets

Child widgets inherit properties from their parents.

Any number of child widgets can be declared, and will be placed to the right
of its parent.

```
conky.widget({
  font = "My Neat Font",
  label = "CPU:",
  conky = "${hwmon 1 temp 1}",   -- cpu temp

  { -- child widget 1 inherits "My Neat Font"
    label = "Core 1:",
    { conky = "${cpu cpu1}" },   -- as does the grandchildren
    { conky = "${cpu cpu2}" },
  },

  { -- child widget 2 inherits "My Neat Font"
    label = "Core 2:",
    { conky = "${cpu cpu3}" },   -- as does the grandchildren
    { conky = "${cpu cpu4}" },
  },

  ....

  {
    font = "Font for Ram"    -- different font for RAM child widget
    label = "RAM:"
    conky = "${memperc}"
  }
})
```

Child widgets inherit subwidget properties from their parent.

```
conky.widget({
  label = "Parent",
  background = { bg = "black" },
  labelbox = { force_width = 30 },
  {
    label = "Child",
    labelbox = { align = "right" },
    {
      -- this widget has a black background,
      -- and a left-aligned label widget 30 pixels wide
      label = "GrandChild",
      labelbox = { align = "left" },
    }
  }
})
```

### Updater Function

To change the widget based on updates from conky, provide
an updater function with the following signature:

`function updater(conky_update, conky_wibox, icon_wibox, label_wibox, background)`

Where `conky_update` is the update from conky, and the rest are the subwidget
wiboxes.

A CPU widget that changes its background color to red if the load goes above 80%:

```
conky.widget({
  label = "CPU:",
  conky = "${cpu}",
  background = { bg = "grey" },

  updater = function(conky_update, conky_wibox, _, _, background)
    conky_wibox:set_text(conky_update)

    if tonumber(conky_update) > 80 then
      background.bg = "red"
    else
      background.bg = "grey"
    end
  end
})
```

### Buttons

Providing a table of button declarations allows you to change the widget
based on button pressed.

A CPU widget that changes its background color to blue while the user holds
CTRL and <mouse1>:

```
conky.widget({
  label = "CPU:",
  conky = "${cpu}",
  background = { bg = "red" },
  buttons = {
    {                      -- declaration of single button
      { "Control" },       -- table of modifiers
      1,                   -- key, here <mouse1>
      function(conkybox, iconbox, labelbox, background)  -- function for
        background.bg = "blue"                           -- button press
      end,
      function(conkybox, iconbox, labelbox, background)  -- (optional) function
        background.bg = "red"                            -- for button release
      end
    },
    ...                    -- more button declarations
  }
})
```

### Signals

Providing a table of signals and conky-awesome connects them for you.

A CPU widget showing the load on all four cores while the mouse hovers over it:

```
local cpu_widget = (function()
  local conkyb = {                    -- properties are not passed to
    forced_width = 30,                -- already built child widgets, so
    align = "right",                  -- shared properties are declared here
  }

  local cores = conky.widget({        -- building the widget here to close
    conkybox = conkyb,                -- up in signal functions below
    { conky = "${cpu cpu1}%" },
    { conky = "${cpu cpu2}%" },
    { conky = "${cpu cpu3}%" },
    { conky = "${cpu cpu4}%" },
  })
  cores.visible = false               -- widget starts out with cores hidden

  return {                            -- widget declaration
    conkybox = conkyb,                -- shared properties
    conky = "${cpu}%",              -- total load %
    signals = {
      ['mouse::enter'] = function(conkybox, iconbox, labelbox, background)
        cores.visible = true          -- on hover, show cores and hide
        conkybox.visible = false      -- total load
      end,
      ['mouse::leave'] = function(conkybox, iconbox, labelbox, background)
        cores.visible = false         -- reset when mouse leaves
        conkybox.visible = true
      end,
    },
    cores,
  }
end)()
```

### Tooltip

Simply a table to pass to [awful.tooltip()](https://awesomewm.org/doc/api/classes/awful.tooltip.html).

A simple 24 hour clock with a date tooltip:

```
conky.widget({
  conky = "${time %R}",
  conkybox = { align = "center" },
  tooltip = {
    timer_function = function() return os.date("%A %B %d %Y") end,
  }
})
```

### Canned Widgets

Canned widgets, located in `awesome/conky/widgets/`, can be included by providing
its filename, without the lua extension, in place of any widget declaration.

```
conky.widget({
  conky = "CPU: ${cpu}"
  {
    "battery"       -- battery widget, from widgets/battery.lua
  }
})
```

Canned widgets can be configured as follows:

```
conky.config.<widget> = { <option> = <value> }
```

To make a canned widget, have the module return a constructor function
that takes a table of options and returns a widget declaration. The top
of the file should contain a comment describing use and configuration.

```
-- usage
--[[
  Description and instructions goes here
--]]

return function(options)
  -- apply options
  return {
    -- declare widget
  }
end
```

Please contribute if you make anything cool or useful.

### Mixins

Mixins, located in `awesome/conky/mixins/`, are for extending a widget
declaration with common functionality. Below the `keep-max` mixin extends
the CPU widget declaration with functionality that tracks and displays both
the current and highest value, in this case CPU core temperature.

```
conky.widget({
  conky.mixin("keep-max", {
    icon = beautiful["icon-hardware-cpu"],
    conky = "${hwmon temp 2} ${hwmon 3 temp 3}",
    {
      conky = ${cpu}% ",
    }
  })
})
```

Any number of mixins may be provided, and they are applied in order to the
provided declaration.

```
conky.mixin("keep-max", "alert-on", ..., <widget declaration>)
```

To make a mixin, have the module return a constructor function
that takes a widget declaration to extend. The top of the file should
contain a comment describing use and configuration.

```
-- usage
--[[
  Description and instructions goes here
--]]

return function(widget_decl)
  <define stuff>
  <extend widget>
  return widget_decl
end
```

## Errors and Debugging

`conky-awesome` will eject widgets that are misbehaving. This means that the
widget will not receive further updates from `conky`. A widget will be ejected
if it throws an error, of it receives an empty string as an update.
`conky-awesome` will display a notification with a widget is ejected.

If you `CTRL+RightClick` on the conky widget, `conky-awesome` will display a
debug feed, showing the variables passed to `conky` together with its last
updated value. The debug feed will also list ejected widgets.

## Caveats and Gotchas

### Conky

If you change your `.conkyrc` while conky is running, conky will restart itself
but appears to not be reloading its lua files. Conky will complain about
`conky_update_awesome` being nil. Simply kill the process and start conky
manually.

### Awesome in Xephyr

If you start a nested awesome in Xephyr, you will need to start it in a
separate dbus session. You can do this by starting the nested awesome with
`dbus-launch awesome`


