#!/usr/bin/env bash
#
# ipynb-reset.sh -- sequentially resets execution counts in an
#                   IPython/Jupyter Notebook
#
# Usage: ipynb-reset.sh <notebook>.ipynb
#
# The output file will be written to <notebook>_reset.ipynb.  We will
# not overwrite the original file since that's too risky.
#

awk '
    BEGIN {
        count = 1
    }

    /^[[:space:]]*"execution_count": [[:digit:]]+,?$/ {
        sub("[[:digit:]]+", count)
        count += 1
    }

    {
        print
    }
' "$1" >"${1%.*}_reset.ipynb"
