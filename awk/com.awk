#!/usr/bin/awk -f
#
# com -- compile anything
#
# Usage: com [-q] <file>...
#
#   -q  Do a trial run without executing any commands
#
# com is a 'Not Invented Here' AWK port of [1].  It looks for lines
# starting with /*% or #% or //% in the supplied files and replaces all
# instances of % in the line with the filename and # with the stem (the
# filename without the extension), and runs the whole line as a shell
# command.
#
# Like the original com, a %% produces a literal %, and a ## produces a
# literal #.  But unlike the original com, this implemenation supports
# filenames with spaces and special characters.  You might need Gawk [2]
# for everything to work properly.
#
# Example:
#
#   $ src="aA1! \"\$\`\\.c"
#   $ cat >"$src" <<EOF
#   > /*% cc -o # %
#   > * a simple "Hello, world" program to illustrate com(1)
#   > * the first line will be used to compile the file */
#   > #include <stdio.h>
#   > main() { printf("hello, world\n"); }
#   > EOF
#   $ com "$src"
#   $ ./"${src%.c}"
#
# There's also a shell script port of com [3].
#
# [1]: http://www.iq0.com/duffgram/com.html
# [2]: https://www.gnu.org/software/gawk/
# [3]: http://chneukirchen.org/blog/archive/2013/07/summer-of-scripts-com.html
#
# NOTE: Retired on 2018-11-25 after porting to Python.
#


BEGIN {
  shell = "/bin/sh"
  null  = sprintf("%c", 0)
  quot  = "\""

  if (ARGV[1] == "-q") {
    shell = ""

    for (i = 1; i < ARGC; i++)
      ARGV[i] = ARGV[i + 1]

    delete ARGV[ARGC]
    ARGC--
  } else if (ARGV[1] ~ /^-/) {
    print "com: " ARGV[1] " is not a valid option" >"/dev/stderr"
    print "usage: com [-q] <file>..." >"/dev/stderr"
    exit 1
  }

  if (ARGC == 1) {
    while ((getline file <".comfile") == 1)
      ARGV[ARGC++] = file

    if (ARGC == 1) {
      print "usage: com [-q] <file>..." >"/dev/stderr"
      exit 1
    }
  } else if (shell != "") {
    print ARGV[1] >".comfile"
    for (i = 2; i < ARGC; i++)
      print ARGV[i] >>".comfile"
  }
}

/^[ \t]*(\/\*|#|\/\/)%/ {
  # Escape special characters in filenames.
  gsub(/^[ \t]*(\/\*|#|\/\/)%/, "")
  gsub("\\\\", "\\\\", FILENAME)
  gsub(/[`$\"]/, "\\\\&", FILENAME)

  gsub("%%", null)
  gsub("%", quot FILENAME quot)
  gsub(null, "%")

  gsub(/\.[^.]+$/, "", FILENAME)

  gsub("##", null)
  gsub("#",  quot FILENAME quot )
  gsub(null, "#")

  if (shell == "")
    print >"/dev/stderr"
  else
    print | shell

  nextfile
}
