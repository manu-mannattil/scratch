#!/usr/bin/awk -f
#
# mmss.awk -- convert MM:SS time intervals to shnsplit format.
#
# This is a handy AWK script that takes song lengths (in MM:SS format)
# in each line, and produces a MM:SS output that shnsplit can use to
# split an audio file.
#
# -m, 2014-12-31 00:03 IST
#

BEGIN {
  seconds = 0
}

function mmss(seconds) {
  min   = int(seconds/60)
  secs  = seconds - min*60
  return sprintf("%02d:%02d", min, secs)
}

{
  split($0, t, ":")
  seconds += t[1]*60 + t[2]
  print mmss(seconds)
}
