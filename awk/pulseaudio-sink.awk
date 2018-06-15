# only read from specified sink

function print_volume(_sink) {
  if (mute[_sink] == "yes") {
    print -vol[_sink]
  } else {
    print vol[_sink]
  }
}

$1 == "Sink"    {
  gsub("#", "")
  s = $2
}

# average left and right speaker
$1 == "Volume:" { vol[s] = (int($5) + int($12)) / 2 }
$1 == "Mute:"   { mute[s] = $2 }

END {
  if (sink in vol) {
    print_volume(sink)
  } else {
    for (s in vol) { any_sink = s }
    if (any_sink) {
      print_volume(any_sink)
    } else {
      print "No Sink"
    }
  }
}
