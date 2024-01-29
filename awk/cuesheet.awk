#!/usr/bin/awk -f
#
# cuesheet.awk -- convert song metadata to cuesheets
#
# This is a handy AWK script that takes song metadata in each line, and
# produces a cuesheet.  The song metadata should be in the format:
#
#   ARTIST   TITLE   DURATION
#
# The fields must be separated by tabs (i.e., by \t's), and the duration
# must be in MM:SS format.
#
# -m, 2017-04-04 19:07 IST
#

BEGIN {
    FS = "\t+"
    track = 1
    seconds = 0

    if (artist == "")
        artist = "<ARTIST>"

    if (album == "")
        album = "<ALBUM>"

    if (file == "")
        file = "<FILE>"

    if (year == "")
        year = "<YEAR>"

    printf("PERFORMER \"%s\"\n", artist)
    printf("TITLE \"%s\"\n", album)
    printf("REM DATE %d\n", year)
    printf("FILE \"%s\"\n", file)
}

function mmss(seconds) {
    min   = int(seconds/60)
    secs  = seconds - min*60
    return sprintf("%02d:%02d:00", min, secs)
}

{
    split($3, t, ":")
    printf("  TRACK %02d AUDIO\n", track)
    printf("    TITLE \"%s\"\n", $2)
    printf("    PERFORMER \"%s\"\n", $1)
    printf("    INDEX 01 %s\n", mmss(seconds))
    track += 1
    seconds += t[1]*60 + t[2]
}
