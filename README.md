# Conky widgets for Awesome WM 4.0

conky-awesome lets you make widgets displaying system information from [conky](https://github.com/brndnmtthws/conky)

## Requirements
* awesome with dbus support
* conky with X support
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

#### Client Window Properties

To set [properties](https://awesomewm.org/apidoc/classes/client.html#Object_properties) for the client window (defaults shown):
```
conky.properties = {
    floating = true,
    sticky = true,
    ontop = false,
    skip_taskbar = true,
    below = true,
    focusable = true
}
```

You can also provide functions to call when the window is raised and lowered

```
conky.raise = function(c) c.opacity = 1.0 end
conky.lower = function(c) c.opacity = 0.4 end
````

## Making Conky Widgets

Conky widget declaration:
```
{
  icon             = <string>,     -- image filename
  label            = <string>,     -- text for a label
  conky            = <string>,     -- the string conky evaluates with conky_parse()
  background       = <table>,      -- background properties table
  updater          = <function>,   -- custom updater function
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
  conky.widget({ conky = "CPU: ${cpu0}% MEM: ${memperc}% GPU: ${hwmon 0 temp 1}" }),
  ....
}
```

### Icons and labels

Simple example with an icon and a text label:
```
conky.widget({
    icon = "my_neat_cpu_icon.png",
    label = "CPU:",
    conky = "${cpu0}"
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
    { conky = "${cpu1}" },   -- as does the grandchildren
    { conky = "${cpu2}" },
  },

  { -- child widget 2 inherits "My Neat Font"
    label = "Core 2:",
    { conky = "${cpu3}" },   -- as does the grandchildren
    { conky = "${cpu4}" },
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

A CPU widget that changes it background color to red if the load goes above 80%:

```
conky.widget({
  label = "CPU:",
  conky = "${cpu0}",
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

### Canned Widgets

Canned widgets, located in `awesome/conky/widgets/`, can be included by providing
its filename, without the lua extension, in place of any widget declaration.

```
conky.widget({
  conky = "CPU: ${cpu0}"
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
that takes a table of options and returns a widget declaration:

```
return function(options)
  -- apply options
  return {
    -- declare widget
  }
end
```

Please contribute if you make anything cool or useful.

## Caveats and Gotchas

### Conky

Conky only runs its lua scripts when the `out_to_x` setting is `true`.
Furthermore, in versions `>=1.10` conky will halt its loop if its window
isn't on the current desktop/tag. This consequently halts the updating of the
widget.

If you change your `.conkyrc` while conky is running, conky will restart itself
but appears to not be reloading its lua files. Conky will complain about
`conky_update_awesome` being nil. Simply kill the process and start conky
manually.

### Awesome in Xephyr

If you start a nested awesome in Xephyr, you will need to start it in a
separate dbus session. You can do this by starting the nested awesome with
`dbus-launch awesome`


