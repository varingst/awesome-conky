# Conky widget for the Awesome WM

Don't want your Window Manager to run around asking how the hardware is doing?
Have Conky do it!  
conky-awesome talks to Conky over DBus.

## Requirements
* awesome with dbus support
* conky with X support
* [lua bindings to dbus](github.com/daurnimator/ldbus)

## Installation
Clone this repo to ~/.config/awesome/conky

## Configuration
in rc.lua:

`local conky = require("conky")`

### Binding keys for Conky's own window

Conky's own window defaults to being behind all others.

Bind F12 to put the on top while the key is held.  
Bind modkey + F12 to toggle whether conky is on top or below all other windows.
```
globalkeys = awful.util.table.join(
    awful.key( .....
    .....
    conky.show_key("F12"),
    conky.toggle_key("F12"), { modkey })
)
```

both functions have this signature:
`_key(keystring, [ modifier table ])`

### Specifying additional properties for Conky's own window

`
conky.rule({ ontop = false, below = true })
`

### Declaring the Conky Widget

Minimal example, just declaring a string to be evaluated by conky:
```
s.mywibox:setup {
  .....
  conky.widget({ conky = "CPU: ${cpu 0}% MEM: ${memperc}% GPU: ${hwmon 0 temp 1}" }),
  ....
}
```

#### Icons and labels

Simple example with an icon and a text label:
```
conky.widget({
    icon = "my_neat_cpu_icon.png",
    label = "CPU:",
    conky = "${cpu%}"
})

```

#### Child widgets

Any number of child widgets can be declared, and will be layed out right of its
parent, going left to right:

```
conky.widget({
    font = "My Neat Font",
    label = "CPU:",
    conky = "${cpu temp},
    { -- child widget 1
      label = "Core 1:",
      { conky = "${cpu0}" },   -- grandchild widget 1
      { conky = "${cpu1}" },   -- grandchild widget 2
    },
    { -- child widget 2
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

Child widgets inherit properties from their parents, 'font' will here apply
to all CPU child widgets, but is overridden for the RAM widget.

#### Composed widgets

The Conky Widget is composed of
  * an `imagebox` for the icon
  * a `textbox` for the label
  * a `textbox` for the string sent from conky
layed out left to right, on top of a `wibox.container.background`

You can specify properties specifically for composed widgets:

```
conky.widget({
  label = "CPU:",
  conky = "${cpu}",
  -- properties for background wibox
  background = { bg = "red" },
  -- properties for the label wibox
  labelbox = { "Font for Label" },
  -- properties for the conky wibox
  conkybox = { force_width = 30, align = "right" },
  -- properties for the icon wibox
  iconbox = { opacity = 0.8 },
})
```

Child widgets inherit composed widget properties from their parent, but can
override.  
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

#### Updater Function

The default widget merely sets the string returning from conky to the
conkybox. For anything more involved a updater function can be supplied:

```
conky.widget({
    label = "CPU:",
    conky = "${cpu}",
    background = { bg = "grey" },
    updater = function(conky_update, conky_wibox, icon_wibox, label_wibox, background)
      conky_wibox:set_text(conky_update)

      if tonumber(conky_update) > 80 then
        background.bg = "red"
      else
        background.bg = "grey"
      end
    end
})
```

Now the CPU widget changes its background color to red if the load goes above 80%

The updater function has the following signature:  
`updater(conky_update, conky_wibox, icon_wibox, label_wibox)`

`conky_update` is the string from conky, use that to make changes  
`icon_wibox` is a [wibox.widget.imagebox](http://awesomewm.org/apidoc/classes/wibox.widget.imagebox.html) instance  
`conky_wibox` and `label_wibox` are instances of [wibox.widget.textbox](http://awesomewm.org/apidoc/classes/wibox.widget.textbox.html)

Take a look at widgets/battery.lua for more

#### Configuration debugging

You can look at what gets sent dbus with the `monitor` script

Conky is launched by the `conky-awesome-launch` script, and run
`conky-awesome-launch restart [conky options]` to restart conky



You declare a conky widget like this:
```
{
  icon    = <string>,     -- image filename
  label   = <string>,     -- a static textbox
  conky   = <string>,     -- what gets passed to conky_parse()
  updater = <function>,   -- updater function, details below
  {                          -- list of any number of:
    <conky declaration>,     -- nested conky widgets
    <canned conky widget>,   -- premade widgets from .config/awesome/conky/widgets
    <any wibox>,             -- if you want other widgets inbetween conky widgets
  }
}
```

