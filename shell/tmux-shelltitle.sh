#!/bin/sh
#
# tmux-shelltitle.sh -- Screen's shelltitle in tmux
#
# This is a hack to emulate GNU Screen's shelltitle feature in tmux.
# I retired this after finding about automatic-rename in tmux.
#
# -m, 2019-05-31 06:21 EDT
#

__update_title() {
    # If no foreground process is launched, print an OSC title setting sequence
    # to set "bash" as the window title.
    case "$TERM" in
        screen*) printf "\033]2;bash\033\\" ;;
        *) printf "\033]0;bash\007" ;;
    esac
}
PROMPT_COMMAND="${PROMPT_COMMAND}; __update_title"

# Each time a command is executed by Bash, it will print out the command name
# surrounded in an OSC title setting string.  However, since we're using
# a PROMPT_COMMAND function, the last command executed is technically
# __bash_prompt.  Thus, __bash_prompt must be appropriately modified for this
# to work (see above).
case "$TERM" in
    screen*) trap 'printf "\033]2;${BASH_COMMAND%% *}\033\\"' DEBUG ;;
    *) trap 'printf "\033]0;${BASH_COMMAND%% *}\007"' DEBUG ;;
esac
