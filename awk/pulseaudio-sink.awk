# only read from specified sink
$1 == "Sink"    { if (int($2) == sink) { read = 1 }
                  else                 { read = 0 } }
# skip to next line if we're not reading
!read           { next }
# average left and right speaker
$1 == "Volume:" { vol = (int($5) + int($12)) / 2 }
$1 == "Mute:"   { m = $2 }
# return volume negated if sink is muted
END             { if (m == "yes") { vol = -vol }
                      print vol }
