#!/usr/bin/awk -f
#
# yes.awk -- UNIX command yes(1) in AWK.
#
# Other yes implementations: https://github.com/mubaris/yes
#
# -m, 2017-02-22 04:09 IST
#

BEGIN {
    if (ARGC > 1) {
        for (i = 1; i <= ARGC; i++)
            string = string " " ARGV[i]

        string = substr(string, 2)
    }
    else
        string = "y"

    while (1)
        print string
}
