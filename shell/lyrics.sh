#!/bin/sh
#
# lyrics -- download and view lyrics of current song in music player
#
# Usage: lyrics [-cf|-e] [-v] [-s <keyword>]
#        lyrics [-frv]
#
#   -c            Write to stdout
#   -e            Open lyrics for song/keyword in $EDITOR
#   -f            Force download lyrics (overwrites cache)
#   -r            Refresh lyrics as song changes
#   -v            Verbose output for debugging
#   -s <keyword>  Use <keyword> to search for lyrics
#
# Since we're using Google's I'm Feeling Lucky to redirect us towards
# the appropriate lyrics page, even approximate queries are handled
# well.  Example:
#
#   $ lyrics -s 'rebecca black friday'
#   $ lyrics -s 'floyd crazy diamond 1'
#
# The function metadata() can be changed to adapt this script to other
# music players.
#
# Example function for Clementine:
#
#   metadata() {
#     qdbus org.mpris.clementine /Player GetMetadata 2>/dev/null |
#     sed -ne '
#       s/^artist: //p
#       s/^title: //p
#     '
#   }
#
# Example function for MPD:
#
#   metadata() {
#     mpc --format '%artist% %title%' | head -n 1
#   }
#
# NOTE: Retired on 2018-11-22 23:42 EST and replaced with a better
# Python script.


cache_dir="${HOME}/music/.lyrics"
http_agent="Mozilla/5.0 (compatible)"
http_referrer="www.google.com"
http_url="http://www.google.com/search?btnI&q=site:letssingit.com"
usage="usage: lyrics [-cf|-e] [-s <keyword>]
       lyrics [-fr]"

die() {
  echo >&2 "$1"
  echo >&2 "$usage"
  exit 1
}

metadata() {
  deadbeef --nowplaying '%a %t' 2>/dev/null

}

sanitize() {
  sed -n -e '
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

extract() {
  sed -ne '
    # Convert XML entities.
    s/&\(amp\|#38\);/\&/g
    s/&\(quot\|#34\);/"/g
    s/&\(apos\|#39\);/'\''/g
    s/&\(lt\|#60\);/</g
    s/&\(gt\|#62\);/>/g

    # Extract song information.
    s/.*<TITLE>\(.*\) Lyrics\( | LetsSingIt\)\?\( Lyrics\)\?<.*/\1\n---/p

    # Extract lyrics.
    /<DIV[^>]*id=lyrics/, /<\/DIV>/ {
      s/<[^>]*>//g

      s/\r$//
      s/\r/\n/g

      s/^[[:space:]]\+//
      s/[[:space:]]\+$//

      p
    }
  '
}

get_lyrics() {
  # $* should be kept unquoted to remove blanks and newlines.
  query=$(echo $* | sanitize)

  mkdir -p "$cache_dir" >/dev/null 2>&1 ||
      die "lyrics: error creating cache directory"

  if [ "$force" != "true" ] && [ -f "${cache_dir}/${query}.txt" ]; then
      cat "${cache_dir}/${query}.txt"
  else
      resp=$(curl $curl_opts      \
          -e "$http_referrer"     \
          -A "$http_agent"        \
          "${http_url}+${query}")
      song=$(echo "$resp" | extract)

      echo "$song" >"${cache_dir}/${query}.txt"
      echo "$song"
  fi
}

stdout=false
edit=false
force=false
reload=false
keyword=$(metadata)
curl_opts="-skL"

while getopts ":cefhrvs:" opt; do
  case "$opt" in
    c)  stdout=true                                        ;;
    e)  edit=true                                          ;;
    f)  force=true                                         ;;
    h)  echo "$usage"; exit 0                              ;;
    r)  reload=true                                        ;;
    v)  curl_opts="${curl_opts} --trace-ascii /dev/stderr" ;;
    s)  keyword="$OPTARG"                                  ;;
    :)  die "lyrics: -${OPTARG} requires an argument"      ;;
    \?) die "lyrics: -${OPTARG} is not a valid option"     ;;
  esac
done


if [ "$edit" = "true" ]; then
  query=$(echo $keyword | sanitize)
  exec $EDITOR "${cache_dir}/${query}.txt"
fi

if [ "$reload" = "true" ]; then
  get_lyrics "$keyword" | less -ic &
  pid=$!

  while true; do
    if [ "$keyword" != "$(metadata)" ]; then
      keyword="$(metadata)"
      kill -9 $pid

      get_lyrics "$keyword" | less -ic &
      pid=$!
    fi
    sleep 5
  done
fi

if [ "$stdout" = "true" ] ; then
  get_lyrics "$keyword"
else
  get_lyrics "$keyword" | less -ic
fi
