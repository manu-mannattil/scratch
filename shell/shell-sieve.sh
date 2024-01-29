#!/bin/sh
#
# Rob Pike's shell sieve.
# https://twitter.com/rob_pike/status/1036498003073200128
#

filter()
{
   read p || exit
   echo $p
   while read x; do
        if [ `expr $x % $p` != 0 ]; then
            echo $x
        fi
    done | filter
}

seq 2 1000 | filter
