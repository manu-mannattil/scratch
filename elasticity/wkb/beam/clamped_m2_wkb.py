"""Clamped beam with varying curvature using WKB/FEM."""

import matplotlib.pyplot as plt
import numpy as np
import scipy.linalg as linalg
from scipy.optimize import root
from scipy.integrate import quad

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

# Slowly varying "curvature".
# Value of curvature at each element.
C, eps = 7, 0.1
m2 = C**2 * np.tanh(eps * x_mid)**2
modes, freqs = eigen(m2)

for i, s in zip((0, 8), ("C0-", "C3-")):
    # Classical turning points.
    tp = np.arctanh(freqs[i] / C) / eps

    plt.plot([tp, tp], [-0.1, 0.25], "C8--")
    plt.plot([-tp, -tp], [-0.1, 0.25], "C8--")

    u = np.hstack([0., modes[i][0:2*nodes - 5:2], 0.])
    u = np.sign(u.mean()) * u
    plt.plot(x, u, s, label="$n = {}$".format(i))

plt.title(r"Clamped beam [$m = C\tanh(\epsilon x)$; $C = {}, \epsilon = {}$]".format(C, eps))
plt.xlabel(r"$x$")
plt.ylabel(r"Displacement $u(x)$")
plt.legend(loc="upper right")
plt.ylim((-0.1, 0.25))
plt.savefig("clamped_m2_wkb_tp.png")

plt.figure()
plt.title("Guess n vs. true n")

n = np.arange(25)
plt.plot(n, n, "C0-")

def guess_n(w):
    # Guess n from a given frequency by integrating the Bohr-Sommerfeld
    # integral.
    tp = np.arctanh(w / C) / eps  # classical turning points
    I = lambda x: (w**2 - C**2 * np.tanh(eps * x)**2)**0.25
    return quad(I, -tp, tp)[0] / np.pi + 0.5 - 1

n_guess = [guess_n(f) for f in freqs[:25]]
plt.plot(n, n_guess, "C3o")
plt.xlabel(r"True $n$")
plt.ylabel(r"Guess $n$")
plt.savefig("clamped_m2_wkb_n.png")

plt.figure()
plt.title("Guess n vs. true n (% error)")

plt.plot((n + 1), (n-n_guess) / (n+1) * 100, "C3o-")
plt.xlabel(r"True $n$")
plt.ylabel(r"Guess $n$ error")
plt.savefig("clamped_m2_wkb_n_error.png")

plt.show()
