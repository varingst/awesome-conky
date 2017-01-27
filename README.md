# Conky widget for the Awesome WM

Don't want your Window Manager to run around asking how the hardware is doing?
Have Conky do it! conky-awesome talks to Conky over DBus.

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
`
globalkeys = awful.util.table.join(
    awful.key( .....
    .....
    conky.show_key("F12"),
    conky.toggle_key("F12"), { modkey })
)
`

both functions have this signature:
`_key(keystring, [ modifier table ])`

### Specifying additional properties for Conky's own window

`
conky.rule({ ontop = false, below = true })
`

### Declaring the Conky Widget

You declare a conky widget like:
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


Minimal example, just declaring a string to be evaluated by conky:
`
s.mywibox:setup {
  .....
  conky.widget({ conky = "CPU: ${cpu 0}% MEM: ${memperc}% GPU: ${hwmon 0 temp 1}" }),
  ....
}
`

#### Icons and labels
The layout order is |ICON|LABEL|CONKY|
`
conky.widget({
    icon = "my_neat_cpu_icon.png",
    label = "CPU:",
    conky = "${cpu%}"
})

`

#### Updater Function

The updater function has the following signature:
updater(conky_update, conky_wibox, icon_wibox, label_wibox)

conky_update is the string from conky, use that to make changes

icon_wibox is a [wibox.widget.imagebox](http://awesomewm.org/apidoc/classes/wibox.widget.imagebox.html) instance, conky_wibox and label_wibox are
instances of [wibox.widget.textbox](http://awesomewm.org/apidoc/classes/wibox.widget.textbox.html)

Take a look at widgets/battery.lua for an example

#### Configuration debugging

You can look at what gets sent dbus with the `monitor` script

Conky is launched by the `conky-awesome-launch` script, and run
`conky-awesome-launch restart [conky options]` to restart conky


