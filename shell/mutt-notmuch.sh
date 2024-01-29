#!/usr/bin/env bash
#
#  mutt-notmuch -- mutt/notmuch integration script
#
#: Usage: mutt-notmuch [-dh] [-o <dir>] <action> <args>
#:
#:   -d        Ignore duplicates (i.e., pass --duplicate=1 to Notmuch)
#:   -h        Show help and exit
#:   -o <dir>  Temporary maildir for creating symlinks.
#:
#: Action can be one of:
#:
#:   o   mutt-notmuch search [<query>]
#:
#:         If a query string is not provided, then it's interactively
#:         read from the user.
#:
#:   o   mutt-notmuch tag <tag>
#:
#:         Read message from stdin and tag it with the given <tag>.
#:         Meant to be used in conjunction with Mutt's <pipe-message>
#:         command.
#:
#:   o   mutt-notmuch thread
#:
#:         Read message from stdin and reconstruct its parent thread.
#:         Meant to be used in conjunction with Mutt's <pipe-message>
#:         command.
#
#  mutt-notmuch is a script to integrate the Notmuch mail indexer with
#  Mutt.  It's much simpler compared to the Perl script [1] distributed
#  with Notmuch (which has a lot of dependencies) or the other popular
#  Python script [2].  Compared to these scripts, mutt-notmuch relies
#  only on standard tools available in most *nix systems.
#
#  You'll also need to configure Mutt to use this script.  An example
#  configuration for Mutt is provided at the end of this file.
#
#  [1]: http://git.notmuchmail.org/git/notmuch/tree/HEAD:/contrib/notmuch-mutt
#  [2]: https://github.com/honza/mutt-notmuch-py
#
#  Requires: mutt, notmuch >= 0.17, sha1sum
#


set -e

usage="usage: mutt-notmuch [-dh] [-o <dir>] <action> <args>"

die() {
  echo >&2 "$1"
  echo >&2 "$usage"
  exit 1
}

clean_maildir() {
  rm -rf "$maildir"
  mkdir -p "${maildir}/cur/"
  mkdir -p "${maildir}/new/"
}

get_message_id() {
  stdin=$(cat)
  id=$(printf "%s\n" "$stdin" |
       awk -F '[<>]' '{
            # Only use the first message id.
            if (tolower($1) ~ /^message-id:/) {
                if (NF > 2) {
                    print $2
                }
                else {
                    do
                        getline
                    while (NF < 2)
                    print $2
                }
                exit
            }
        }')

  if [ -n "$id" ]; then
    printf "%s" "$id"
  else
    # If no Message-ID is found use the SHA1 digest.
    digest=$(printf "%s" "$stdin" | sha1sum | cut -d ' ' -f 1)
    printf "notmuch-sha1-%s" "$digest"
  fi
}

search() {
  if [ "$#" -eq 0 ]; then
    read -erp "Query (notmuch): " query
  else
    query="$1"
  fi

  clean_maildir
  notmuch search $duplicate --output=files "$query" |
  xargs -I % ln -s % "${maildir}/cur/"
}

tag() {
  if [ "$#" -eq 0 ]; then
    echo >&2 "mutt-notmuch: requires at least one tag to add or remove"
    exit 1
  else
    id=$(get_message_id)
    notmuch tag "$1" -- "id:${id}"
    echo >&2 "mutt-notmuch: tagged ${id} with ${1}"
  fi
}

thread() {
  id=$(get_message_id)
  tid=$(notmuch search --output=threads "id:${id}")
  clean_maildir
  search "$tid"
}

duplicate=
maildir="$HOME/.cache/mutt/notmuch"

while getopts ":dho:" opt; do
  case "$opt" in
    d)  duplicate="--duplicate=1"                             ;;
    h)  echo >&2 "$usage"; exit                               ;;
    o)  maildir="$OPTARG"                                     ;;
    :)  die "mutt-notmuch: -${OPTARG} requires an argument"   ;;
    \?) die "mutt-notmuch: -${OPTARG} is not an valid option" ;;
  esac
done
shift $(( OPTIND - 1 ))

case "$1" in
  search) shift; search "$@"                                          ;;
  tag)    shift; tag "$@"                                             ;;
  thread) shift; thread                                               ;;
  "")     die "mutt-notmuch: at least one action should be specified" ;;
  *)      die "mutt-notmuch: unknown action"                          ;;
esac

#
# Example Mutt configuration.
#
#   Key    Action
#
#    \     Search mail using notmuch.
#    X     Add 'delete' tag to current message.
#    Y     Remove 'delete' tag from current message.
#    E     Expand (reconstruct) parent thread of current message.
#
# Tagging a message with 'delete' does not delete it.  To actually
# delete the tagged messages, search for messages with the 'delete' tag
# and remove them appropriately.  For example,
#
#   $ notmuch search --output=files tag:delete | xargs rm
#

#
# # Search mail using Notmuch.
# macro index,pager \\ \
# "<enter-command>set my_old_pipe_decode=\$pipe_decode my_old_wait_key=\$wait_key nopipe_decode nowait_key<enter>\
# <shell-escape>mutt-notmuch -d -o ~/.cache/mutt/notmuch search<enter>\
# <change-folder-readonly>~/.cache/mutt/notmuch<enter>\
# <enter-command>set pipe_decode=\$my_old_pipe_decode wait_key=\$my_old_wait_key<enter>" \
#       "notmuch: search mail"
#

#
# # Add 'delete' tag to message.
# macro index,pager X \
# "<enter-command>set my_old_pipe_decode=\$pipe_decode my_old_wait_key=\$wait_key nopipe_decode nowait_key<enter>\
# <pipe-message>mutt-notmuch tag +delete<enter>\
# <next-entry>\
# <enter-command>set pipe_decode=\$my_old_pipe_decode wait_key=\$my_old_wait_key<enter>" \
#       "notmuch: add 'delete' tag to message"
#

#
# # Remove 'delete' tag from message.
# macro index,pager Y \
# "<enter-command>set my_old_pipe_decode=\$pipe_decode my_old_wait_key=\$wait_key nopipe_decode nowait_key<enter>\
# <pipe-message>mutt-notmuch tag -delete<enter>\
# <next-entry>\
# <enter-command>set pipe_decode=\$my_old_pipe_decode wait_key=\$my_old_wait_key<enter>" \
#       "notmuch: remove 'delete' tag from message"
#

#
# # Expand thread containing the message.
# macro index,pager E \
# "<enter-command>set my_old_pipe_decode=\$pipe_decode my_old_wait_key=\$wait_key nopipe_decode nowait_key<enter>\
# <pipe-message>mutt-notmuch -o ~/.cache/mutt/notmuch thread<enter>\
# <change-folder-readonly>~/.cache/mutt/notmuch<enter>\
# <enter-command>set pipe_decode=\$my_old_pipe_decode wait_key=\$my_old_wait_key<enter>" \
#       "notmuch: expand thread"
#
