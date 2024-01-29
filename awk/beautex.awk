#!/usr/bin/awk -f
#
# NAME
#
#   BeauTeX - a LaTeX code beautifier
#
# SYNOPSIS
#
#   beautex [<file>...]
#
# DESCRIPTION
#
#   BeauTeX is a LaTeX code beautifier.  It will attempt to
#
#     (a) keep each sentence in a single line;
#     (b) re-indent \begin, \end environments without re-wrapping them.
#
#   BeauTeX, although quite beautiful, is not very smart and does not
#   work well.  Considerable post-processing might be required to make
#   the code really pretty.  Nonetheless, BeauTeX's output can be used
#   as a starting point to deal with garbled LaTeX.  It's also advisable
#   to give BeauTeX parts of the document than the whole document at
#   once.
#
# SEE ALSO
#
#   texpretty, LaTeXTidy, etc.
#
# NOTES
#
#   I retired this in 2018 after I found out about latexindent.
#

BEGIN {
  indent = -2
}

# Remove original indentation and compress spaces.
{
  sub(/^[ \t]+/, "")
  sub(/[ \t]+$/, "")
  gsub(/[ \t]+/, " ")
}

/^\\end{/ {
  indent -= 2
}

! /(^%|^$)/ && (indent <= 0) {
  # If there's a hard wrap, insert a space.
  sub(/[^.!?]$/, "& ")

  # If the line completes a sentence, insert a newline.
  sub(/[.!?]['"})\]]?$/, "&\n")

  # Split the line at other "sentence ends".
  gsub(/[.!?]['"})\]]?[ \t]+/, "&\n")

  printf("%s", $0)
}

/(^%|^$)/ || (indent > 0) {
  if (indent > 0)
    printf("%" indent "s%s\n", "", $0)
  else
    print
}

/^\\begin{/ {
  indent += 2
}
