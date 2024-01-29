# -*- coding: utf-8 -*-

# An f-string is a literal string, prefixed with ‘f’, which contains
# expressions inside braces.  These expressions are evaluated at run
# time.  https://peps.python.org/pep-0498/

import math

# output: 1 + 1 vs 2
print(f"1 + 1 vs {1 + 1}")

# zero padding for integers
x = 1
print(f"{x:05}")

# width for integers
x = 1
print(f"{x:5}")

# width and precision for floats
width = 10
precision = 5
print(f"π = {math.pi:{width}.{precision}}")

# output: sin(π/4) is 0.7071067811865475.
print(f"sin(π/4) is {math.sin(math.pi/4)}")

fruits = ["apple", "orange", "grape"]

# output: apple
print(f"{fruits[0]}")

fruits = "not a fruit"

# output: not a fruit
print(f"{fruits}")
