# Conky widget for Awesome WM

conky-awesome lets you make widgets displaying system information from [conky](https://github.com/brndnmtthws/conky)

## Requirements
* awesome with dbus support
* conky with X support
* [lua bindings to dbus](github.com/daurnimator/ldbus)

## Installation
Clone this repo to ~/.config/awesome/conky

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

The conky client's own window defaults to being behind all others.

Bind keys for raising the client window.

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

You can provide a table of properties for the client window, and functions
to apply when the window is raised and lowered

```
conky.properties({ opacity = 0.4 })
conky.raise = function(c) c.opacity = 1.0 end
conky.lower = function(c) c.opacity = 0.4 end
````

## Conky Widgets

Conky widget declaration:
```
{
  icon       = <string>,     -- image filename
  label      = <string>,     -- a static textbox
  conky      = <string>,     -- the string conky evaluates with conky_parse()
  background = <table>,      -- background properties table
  updater    = <function>,   -- custom updater function
  {                          -- list of any number of:
    <conky declaration>,     -- nested conky widget declarations
    <canned conky widget>,   -- premade widgets from .config/awesome/conky/widgets
    <any widget>,            -- if you want other widgets in-between conky widgets
  }
}
```

A conky widget consists of up to four subwidgets, all optional:
  - `icon` declares a [wibox.widget.imagebox](http://awesomewm.org/apidoc/classes/wibox.widget.imagebox.html) instance
  - `label` declares a [wibox.widget.imagebox](http://awesomewm.org/apidoc/classes/wibox.widget.imagebox.html) instance
  - `conky` declares a [wibox.widget.imagebox](http://awesomewm.org/apidoc/classes/wibox.widget.imagebox.html) instance
  - `background` declares a [wibox.container.background](http://awesomewm.org/apidoc/classes/wibox.container.background.html) instance

### A minimal widget

Simply declaring a string to be evaluated by conky:
```
s.mywibox:setup {
  .....
  conky.widget({ conky = "CPU: ${cpu 0}% MEM: ${memperc}% GPU: ${hwmon 0 temp 1}" }),
  ....
}
```

### Icons and labels

Simple example with an icon and a text label:
```
conky.widget({
    icon = "my_neat_cpu_icon.png",
    label = "CPU:",
    conky = "${cpu%}"
})

```

### Child widgets

Any number of child widgets can be declared, and will be layed out to the right
of its parent.
Child widgets inherit properties from their parents.

```
conky.widget({
    font = "My Neat Font",
    label = "CPU:",
    conky = "${cpu temp},
    { -- child widget 1        -- Inherits "My Neat Font"
      label = "Core 1:",
      { conky = "${cpu0}" },   -- grandchild widget 1
      { conky = "${cpu1}" },   -- grandchild widget 2
    },
    { -- child widget 2        -- Inherits "My Neat Font"
      label = "Core 2:",
      { conky = "${cpu2}" },   -- grandchild widget 3
      { conky = "${cpu3}" },   -- grandchild widget 4
    },
    ....
    {
      font = "Font for Ram"    -- RAM child widget wants a different font
      label = "RAM:"
      conky = "${memperc}"
    }
})
```

### Subwidgets

You can specify wibox properties individually for subwidgets:

```
conky.widget({
  label = "CPU:",
  conky = "${cpu}",

  -- properties for background wibox
  background = { bg = "red" },

  -- properties for the label wibox
  labelbox = { font = "Font for Label" },

  -- properties for the conky wibox
  conkybox = { force_width = 30, align = "right" },

  -- properties for the icon wibox
  iconbox = { opacity = 0.8 },
})
```

Child widgets inherit subwidget properties from their parent.

The GrandChild widget below aligns text left to right, has a 30px fixed width, and a
black background:

```
conky.widget({
    label = "Parent",
    background = { bg = "black" },
    labelbox = { force_width = 30 },
    {
      label = "Child",
      labelbox = { align = "right" },
      {
        label = "GrandChild",
        labelbox = { align = "left" },
      }
   }
})
```

### Updater Function

The default widget jest sets the string returning from conky to the
conkybox. To change the widget based on updates from conky, you can provide
an updater function with the following signature:

`function updater(conky_update, conky_wibox, icon_wibox, label_wibox, background)`

Where `conky_update` is the update from conky, and the rest are the subwidget
wiboxes.

A CPU widget that changes it background color to red if the load goes above 80%:

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

Take a look at widgets/battery.lua for more

### Canned widgets

Premade widgets in awesome/conky/widgets/ can be included by providing its filename,
without the lua extension, in place of any widget declaration.

```
conky.widget({
  conky = "${cpu}"
  {
    "battery"       -- battery widget, from widgets/battery.lua
  }
})
```

## Caveats and Gotchas

### Conky

Conky only runs its lua scripts when the `out_to_x` setting is `true`.
Furthermore, in versions `>=1.10` conky will halt its loop if its window
isn't on the current desktop. This consequently halts the updating of the
widget.

### Awesome in Xephyr

If you start a nested awesome in Xephyr, you will need to start this in a
separate dbus session. You can do this by starting the nested awesome with
`dbus-launch --sh-syntax --exit-with-session awesome [awesome-options]`


