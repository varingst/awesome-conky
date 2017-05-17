function match_interface(iface) {
  return match($0, "interface=" iface ";")
}

function match_directive(dir) {
  return match_interface("org.freedesktop.DBus") && match($NF, "member=" dir)
}


print_line {
  print
  print_line = 0
}

register_new {
  if (new_addr != $NF) {
    addr[new_addr] = $NF
    printf "Name Acquired: %s -> %s\n", new_addr, $NF
    register_new = 0
  }
}


match_interface(update_for_widget) {
  print "Conky sent a widget update:"
  print_line = 1
  next
}

match_interface(string_for_conky) {
  print "Awesome sent a string:"
  print_line = 1
  next
}

match_directive("NameAcquired") {
  new_addr = $5
  register_new = 1
  sub(/destination=/, "", new_addr)
}

