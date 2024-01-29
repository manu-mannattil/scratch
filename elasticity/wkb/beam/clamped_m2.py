"""Clamped beam with varying curvature using finite elements."""

import matplotlib.pyplot as plt
import numpy as np
import scipy.linalg as linalg

E = 1.  # elastic modulus
I = 1.  # moment of area
mu = 1.  # mass/length
L = 50.  # total length

N = 350  # number of elements
nodes = N + 1  # number of nodes
h = L / N  # length of beam element
x = np.arange(-L / 2, L/2 + h, h)

# See 44m:44s of https://www.youtube.com/watch?v=RFH6i8ER284 for the
# definition of the element stiffness/mass matrices.
K_e = E * I / h**3 * np.array([[12, 6 * h, -12, 6 * h], [6 * h, 4 * h**2, -6 * h, 2 * h**2],
                               [-12, -6 * h, 12, -6 * h], [6 * h, 2 * h**2, -6 * h, 4 * h**2]])
A_e = h / 420 * np.array([[156, 22 * h, 54, -13 * h], [22 * h, 4 * h**2, -13 * h, -3 * h**2],
                          [54, 13 * h, 156, -22 * h], [-13 * h, -3 * h**2, -22 * h, 4 * h**2]])

M_e = mu * A_e

# Middle point of each element.
x_mid = 0.5 * (x[:-1] + x[1:])

def eigen(m2):
    """Find eigenmodes and frequencies."""
    K = np.zeros((2 * (N+1), 2 * (N+1)))
    M = np.zeros((2 * (N+1), 2 * (N+1)))

    # Assemble global stiffness/mass matrix.
    for i in range(1, N + 1):
        K[2 * (i-1):2 * (i-1) + 4][:, 2 * (i-1):2 * (i-1) + 4] += K_e + m2[i - 1] * A_e
        M[2 * (i-1):2 * (i-1) + 4][:, 2 * (i-1):2 * (i-1) + 4] += M_e

    # Clamped-clamped BCs.
    K = np.delete(K, [2*nodes - 2, 2*nodes - 1], 0)
    K = np.delete(K, [2*nodes - 2, 2*nodes - 1], 1)
    K = np.delete(K, [0, 1], 0)
    K = np.delete(K, [0, 1], 1)
    M = np.delete(M, [2*nodes - 2, 2*nodes - 1], 0)
    M = np.delete(M, [2*nodes - 2, 2*nodes - 1], 1)
    M = np.delete(M, [0, 1], 0)
    M = np.delete(M, [0, 1], 1)

    # Find eigenvalues and eigenvectors.
    freqs, modes = linalg.eig(K, M)
    i = np.argsort(freqs)
    # The freqs matrix has to be transposed before sorting.
    return modes.T[i].real, np.sqrt(freqs[i].real)

# Constant curvature.
C = 7
m2_const = [C**2] * N
modes_const, freqs_const = eigen(m2_const)

for i in range(0, 11, 2):
    u = np.hstack([0., modes_const[i][0:2*nodes - 5:2], 0.])
    u = np.sign(u.mean()) * u
    plt.plot(x, u, label="$n = {}$".format(i))

plt.title(r"Clamped beam ($m = C = {}$)".format(C))
plt.xlabel(r"$x$")
plt.ylabel(r"Displacement $u(x)$")
plt.legend()
plt.savefig("clamped_m2_const.png")

# Slowly varying "curvature".
# Value of curvature at each element.
eps = 0.2
m2_slow = C**2 * np.tanh(eps * x_mid)**2
modes_slow, freqs_slow = eigen(m2_slow)

plt.figure()
for i in range(0, 11, 2):
    u = np.hstack([0., modes_slow[i][0:2*nodes - 5:2], 0.])
    u = np.sign(u.mean()) * u
    plt.plot(x, u, label="$n = {}$".format(i))

plt.title(r"Clamped beam [$m = C\tanh(\epsilon x)$; $C = {}, \epsilon = {}$]".format(C, eps))
plt.xlabel(r"$x$")
plt.ylabel(r"Displacement $u(x)$")
plt.legend(loc="upper right")
plt.savefig("clamped_m2_slow.png")

# Compare frequencies.
plt.figure()
for f in freqs_const[:50]:
    plt.plot([0, 1], [f, f], "C2-")

for f in freqs_slow[:50]:
    plt.plot([2, 3], [f, f], "C3-")

plt.plot([-1, 4], [C, C], "C5--")

plt.title(r"Eigenfrequencies (const vs. slow)")
plt.ylabel(r"Frequency")
plt.savefig("clamped_m2_compare.png")
plt.show()
