#!/bin/sh
#
# polishsub.sh -- wrapper for faster cleanup of SRT subtitles
#
# Requires: srtpol, 2utf8
#

if [ $# -eq 0 ]; then
  echo >&2 "usage: polishsub.sh <file>..."
  exit 1
else
  for f in "$@"; do
    tmp=$(mktemp)
    2utf8 "$f" >"$tmp"
    srtpol "$tmp" >"$f"
    rm -f "$tmp"
  done
fi
