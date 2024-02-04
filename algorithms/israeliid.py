#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Israeli IDs are validated using a simple Luhn check.
# More details on the Hebrew Wikipedia article:
#   https://he-m-wikipedia-org.translate.goog/wiki/ספרת_ביקורת?_x_tr_sl=auto&_x_tr_tl=en
#

val = 3201579484

def check_digit(val):
    val = str(val)
    total = 0
    for i in range(8):
        digit = int(val[i])
        if i % 2 == 0:
            total += digit
        else:
            if digit < 5:
                total += digit*2
            else:
                total += 1 + (2*digit) % 10

    return (10 - (total % 10)) % 10

def validate(val):
    return check_digit(val) == val % 10

print(check_digit(val))
print(validate(val))
