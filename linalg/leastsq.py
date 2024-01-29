# Least squares using NumPy.
# I alway keep forgetting how to make the coefficient matrix.

import numpy as np
import matplotlib.pyplot as plt

x = np.linspace(0, 10, 100)
y = np.pi * x + np.random.random(100)

# Make the coefficient matrix; note the transpose.
A = np.vstack([x, np.ones(len(x))]).T

m, c = np.linalg.lstsq(A, y)[0]

plt.plot(x, y, '.')
plt.plot(x, m*x + c)

plt.show()
