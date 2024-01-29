#!/usr/bin/env bash
#
# clean-desktop.sh -- clean temporary/cache files in a GNU/Linux desktop
#
# A silly cleanup script to `clean' an XFCE GNU/Linux desktop by
# removing temporary files.
#

# [[ $(id -u) == 0 ]] || exec sudo -- /usr/bin/env bash "$0" "$@"

echo "\
This script will PERMANENTLY remove cache files and other 'temporary'
files, which may affect the performance of your system."

read -r -p "Do you wish to continue [y/n]? "
[[ $REPLY =~ ^(y|Y) ]] || {
    echo "Aborted."
    exit 1
}

# Empty a directory
empty() {
    echo >&2 "Emptying '${1}'"
    rm -vrf "$1"
    mkdir -vp "$1"
}

# Kill instances of LaTeX
killall -9   \
    biber    \
    bibtex   \
    latex    \
    latexmk  \
    latexrun \
    pdflatex \
    pslatex  \
    xelatex  \
    xetex    &>/dev/null

# Clean temporary LaTeX files.
texclean "${HOME}/"{code,documents,templates}

# Mozilla Firefox
killall -15 firefox &>/dev/null
rm -vrf ~/.mozilla/firefox/Crash\ Reports
find ~/.mozilla -type f -name "content-prefs.sqlite" -delete
find ~/.mozilla -type f -name "cookies.sqlite" -delete
find ~/.mozilla -type f -name "crashes" -delete
find ~/.mozilla -type f -name "datareporting" -delete
find ~/.mozilla -type f -name "formhistory.sqlite" -delete
find ~/.mozilla -type f -name "minidumps" -delete
find ~/.mozilla -type f -name "sessionstore.js" -delete
find ~/.mozilla -type f -name "sessionstore.mozlz4" -delete
find ~/.mozilla -type f -name "storage" -delete
find ~/.mozilla -type f -name "storage.sqlite" -delete
find ~/.mozilla -type f -name "webappsstore.sqlite" -delete

# Google Chrome
killall -15 google-chrome &>/dev/null
killall -15 chrome &>/dev/null
rm -vrf ~/.config/google-chrome

# Clean `standard' ~/.cache directory
empty ~/.cache/mutt/attach
empty ~/.cache/mutt/notmuch
empty ~/.cache/mutt/headers
empty ~/.cache/vim/swap
empty ~/.cache/vim/backup
empty ~/.cache/vim/undo
empty ~/.cache/rlwrap

# Vim
rm -vrf ~/.cache/viminfo

# XDesktop
rm -vrf ~/.thumbnails
rm -vrf ~/.cache/thumbnails
rm -vrf ~/.local/share/Trash

# VLC
rm -vrf ~/.vlc/vlc-qt-interface.conf
rm -vrf ~/.config/vlc/vlc-qt-interface.conf
rm -vrf ~/.cache/vlc

# MPV
rm -vrf ~/.mpv/watch_later
rm -vrf ~/.config/mpv/watch_later

# Commandline
# NOTE (2018-05-26): For reasons I don't fully understand, readline screws up
# the history-search-forward/backward functions (set in ~/.inputrc) when the
# first line of $HISTFILE is _not_ a blank line.  Basically, a two word command
# like `echo a' gets completed twice if the first line of $HISTFILE isn't
# a blank line.
# rm -vrf "${HISTFILE:-${HOME}/.bash_history}"
printf "\n" >| "${HISTFILE:-${HOME}/.bash_history}"

rm -vrf ~/.sdcv_history
find ~/.ipython -type f -name "history.sqlite" -delete

# QPDFView
sed -i '/\(recentlyUsed\|openPath\)/d' ~/.config/qpdfview/qpdfview.conf

# Python history
rm -vrf ~/.python_history

# Gnuplot history
rm -vrf ~/.gnuplot_history

# w3m
rm -vrf ~/.w3m/cookie
rm -vrf ~/.w3m/history

# elinks
rm -vrf ~/.elinks/cookies
rm -vrf ~/.elinks/globhist

# Lynx
rm -vrf ~/.lynx_cookies

# Less
rm -vrf "${LESSHISTFILE:-${HOME}/.lesshst}"

# torrents
rm -vrf ~/*.torrent
rm -vrf ~/downloads/*.torrent

# fasd
rm -vrf ~/.fasd*

# Clear clipboard
for selection in "primary" "secondary" "clipboard"
do
    echo | xclip -selection "$selection"
done

# Wget known hosts
rm -vrf ~/.wget-hsts

# Mamba/conda
mamba clean --all

deb-squeaky-clean
