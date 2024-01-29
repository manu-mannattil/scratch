"""Cantilevered beam using finite elements."""

import matplotlib.pyplot as plt
import numpy as np
import scipy.linalg as linalg

E = 1.                     # elastic modulus
I = 1.                     # moment of area
mu = 1.                    # mass/length
L = 1.                     # total length

N = 100                    # number of elements
nodes = N + 1              # number of nodes
h = L / N                  # length of beam element
x = np.arange(0, h + L, h)

# See 44m:44s of https://www.youtube.com/watch?v=RFH6i8ER284 for the
# definition of the element stiffness/mass matrices.
K_e = E * I / h**3 * np.array([
    [12, 6 * h, -12, 6 * h],
    [6 * h, 4 * h**2, -6 * h, 2 * h**2],
    [-12, -6 * h, 12, -6 * h],
    [6 * h, 2 * h**2, -6 * h, 4 * h**2]
])
M_e = mu * h / 420 * np.array([
    [156, 22 * h, 54, -13 * h],
    [22 * h, 4 * h**2, -13 * h, -3 * h**2],
    [54, 13 * h, 156, -22 * h],
    [-13 * h, -3 * h**2, -22 * h, 4 * h**2]
])

K = np.zeros((2 * (N+1), 2 * (N+1)))
M = np.zeros((2 * (N+1), 2 * (N+1)))

# Assemble global stiffness/mass matrix.
for i in range(1, N + 1):
    K[2 * (i-1):2 * (i-1) + 4][:, 2 * (i-1):2 * (i-1) + 4] += K_e
    M[2 * (i-1):2 * (i-1) + 4][:, 2 * (i-1):2 * (i-1) + 4] += M_e

# Cantilever BCs.
K = np.delete(K, [0, 1], 0)
K = np.delete(K, [0, 1], 1)
M = np.delete(M, [0, 1], 0)
M = np.delete(M, [0, 1], 1)

# Find eigenvalues and eigenvectors.
freqs, modes = linalg.eig(K, M)
i = np.argsort(freqs)
# The freqs matrix has to be transposed before sorting.
modes, freqs = modes.T[i].real, np.sqrt(freqs[i].real)

for i in range(5):
    # Cantilever.
    u = np.hstack([0., modes[i][0:2*nodes - 2:2]])
    u = np.sign(u.mean()) * u
    plt.plot(x, u, label="$m = {}$".format(i + 1))

plt.title(r"Cantilever eigenmodes")
plt.xlabel(r"$x$")
plt.ylabel(r"Displacement $u(x)$")
plt.legend()
plt.show()
