#!/usr/bin/awk -f
#
# youtube2srt.awk -- XML YouTube subtitles to SubRip (SRT) format
#
# Getting the XML subtitles from YouTube videos might prove to be a bit
# difficult.  The easiest way is to open up the network monitor in
# Firebug, or Firefox's Page Inspector, or WebKit's Web Inspector and
# look for a XML file named "timedtext?<parameters>".  For English
# subtitles it's usually at:
#
#   http://video.google.com/timedtext?lang=en&v=<video-id>      OR
#   http://video.google.com/timedtext?lang=en_GB&v=<video-id>
#
# Example:
#   curl -A 'Mozilla/5.0 (compatible)' \
#        -skL 'http://video.google.com/timedtext?lang=en&v=zJOS0sV2a24' |
#        youtube2srt
#
# Retired c. early 2015 because I found out that youtube-dl has the
# exact same capabilities.
#
# -m, 2014-06-22 00:00 IST
#

BEGIN {
  RS = "</text>"
  FS = "\n"
  FN = 1
}

function subtime(seconds) {
  hours = int(seconds/3600)
  min   = int((seconds - hours*3600)/60)
  secs  = int((seconds - hours*3600 - min*60))
  msecs = int((seconds - hours*3600 - min*60 - secs)*1000)

  return sprintf("%02d:%02d:%02d,%03d", hours, min, secs, msecs)
}

function cleanup(string) {
  # Decode XML entities.
  # The second gsub isn't a repetition!
  gsub("&amp;", "\\&", string)
  gsub("&amp;", "\\&", string)
  gsub("&quot;", "\"", string)
  gsub("&apos;", "'", string)
  gsub("&lt;", "<", string)
  gsub("&gt;", ">", string)

  # Convert Unicode code points into appropriate characters.
  while (match(string, /&#[0-9]+;/) != 0) {
    cp = substr(string, RSTART, RLENGTH)
    gsub(/(^&#|;$)/, "", cp)
    gsub("&#" cp ";", sprintf("%c", int(cp)), string)
  }

  # Strip leading and trailing whitespace.
  gsub("^[[:space:]]+", "", string)
  gsub("[[:space:]]+$", "", string)

  return string
}

{
  for (line = 1; line <= NF; line++) {
    if (match($line, /<text start="[^>"]+" *dur="[^>"]+">/) != 0) {
      start = substr($line, RSTART, RLENGTH)
      gsub(/(^<text start="|".*$)/, "", start)

      end = substr($line, RSTART, RLENGTH)
      gsub(/(^.*dur="|".*$)/, "", end)

      end = subtime(start + end)
      start = subtime(start)

      break
    }
  }

  gsub(/<[^>]*>/, "")

  print FN
  print start, "-->", end
  for (i = line; i <= NF; i++)
    print cleanup($i)

  FN++
  print "\n"
}
