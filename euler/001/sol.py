#!/usr/bin/env python
# -*- coding: utf-8 -*-

# Brute force.
total = 0
for i in range(1, 1000):
    if i % 3 == 0 or i % 5 == 0:
        total += i

print("Brute force = {}".format(total))

# Better solution.
sumn = lambda n: int(n*(n + 1)/2)
factor = lambda m, n: min(int(m/n), m/n - 1)

three = 3*sumn(int(999/3))
five = 5*sumn(int(999/5))
fifteen = 15*sumn(int(999/15))

print("Better solution = {}".format(three + five - fifteen))
