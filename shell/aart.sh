#!/bin/sh
#
# aart.sh -- download album art from Last.fm
#
# Usage: aart [-v] [-o <file>] [-s <size>] <query>
#        aart [-uv] <query>
#
#   -u         Print album art URL to stdout and exit
#   -v         Verbose output for debugging
#   -o <file>  Write image to <file> (converted according to
#              extension).  By default the album art is written to
#              album.jpg.
#   -s <size>  Crop and resize as a square of side <size>
#
# Since we're using Google's I'm Feeling Lucky to redirect us towards
# the appropriate Last.fm page, even approximate queries are handled
# well.  Example:
#
#   $ aart -o wall.png 'floyd wall'
#
# Requires: convert (ImageMagick), curl
#
#                                 ***
#
# I retired this script on 2017-03-13.  Last.fm's page format keeps
# changing, and I can't keep up.  I think this script used to work fine
# in 2016.  Rather than scraping webpages, I should be using the more
# mature way of doing things by using an API.
#


http_agent="Mozilla/5.0 (compatible)"
http_referer="www.google.com"
search_url="http://www.google.com/search?btnI&q=site:last.fm"
usage="usage: aart [-v] [-o <file>] [-s <size>] <query>
       aart [-uv] <query>"

die() {
  echo >&2 "$1"
  echo >&2 "$usage"
  exit 1
}

sanitize() {
  sed -ne '
    s/ ([^)]*)//g
    s/ {[^}]*}//g
    s/ \[[^]]*\]//g
    s/ [\/].*$//
    s/^[^[:alnum:]]\+//
    s/[^[:alnum:]]\+$//
    s/[^[:alnum:]]\+/+/g
    y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/
    p
  '
}

size=
output=album.jpg
urlonly=false
curl_opts="-skL"

while getopts ":uvo:s:" opt; do
  case "$opt" in
    u)  urlonly=true                                       ;;
    v)  curl_opts="${curl_opts} --trace-ascii /dev/stderr" ;;
    o)  output="$OPTARG"                                   ;;
    s)  size="$OPTARG"                                     ;;
    :)  die "aart: -${OPTARG} requires an argument"        ;;
    \?) die "aart: -${OPTARG} is not a valid option"       ;;
  esac
done
shift $(( OPTIND - 1 ))

if [ "$#" -eq 0 ]; then
  die "aart: missing query"
else
  query=$(echo $@ | sanitize)
  resp=$(curl $curl_opts                \
              -e "$http_referer"        \
              -A "$http_agent"          \
              "${search_url}+${query}")
  echo "$resp"
  image=$(echo "$resp" |
          sed -ne 's|.*\(https\?://img2-ak.lst.fm/i/u\)/174s/\([^"]*\)".*|\1/\2|p')
fi

if [ -z "$image" ]; then
  echo >&2 "aart: no album art found for query: ${@}"
  exit 1
elif [ "$urlonly" = "true" ]; then
  echo "$image"
  exit 0
else
  echo >&2 "$image"

  if [ -n "$size" ]; then
    curl -A "$http_agent" -#kL "$image" | convert - -resize ${size}x${size}^  \
                                                    -gravity center           \
                                                    -crop ${size}x${size}+0+0 \
                                                    "$output"
  else
    curl -A "$http_agent" -#kL "$image" | convert - "$output"
  fi
fi
