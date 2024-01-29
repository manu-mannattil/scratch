#!/usr/bin/awk -f
#
# unwrap.awk -- unwrap wrapped text
#
# This is a simple script to "unwrap" hardwrapped text.  Useful to read
# film scripts on the Kindle.
#
# -m, 2020-09-16 17:01 EDT
#

BEGIN {
  para = 0
}

{
  if ($0 ~ /(^$|^[[:space:]]+)/) {
    if (para == 1) {
      print "\n" $0
      para = 0
    }
    else {
      print $0
    }
  }
  else {
    printf("%s ", $0)
    para = 1
  }
}
