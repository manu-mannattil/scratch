"""N-queens problem."""

from itertools import permutations

n = 8

def clear(cols):
    for i in range(n):
        for j in range(i + 1, n):
            if abs(cols[j] - cols[i]) == (j - i):
                return False

    return True

numsol = 0
for cols in permutations(range(n)):
    if clear(cols):
        numsol +=1

print(numsol)
