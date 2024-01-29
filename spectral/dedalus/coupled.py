# -*- coding: utf-8 -*-

"""Coupled eigenvalue system.

Consider the differential operator D acting on a multicomponent vector
field (f, g) and defined by

    D = [[k    -omega]
        [-omega    k]]

where k = -i d/dx, the momentum operator.  This is equivalent to
d^2f/dx^2 + omega^2 f = 0 and D is clearly Hermitian.  In the interval
[0, pi], assuming the boundary conditions f(0) = f(pi) = 0, omega values
are 0, +/- 1, +/- 2, ...
"""

import numpy as np
import matplotlib.pyplot as plt
import dedalus.public as d3
from scipy.integrate import trapezoid

# Parameters
L = np.pi    # interval length
N = 128    # number of collocation points

# Bases
coord = d3.Coordinate("x")
dist = d3.Distributor(coord, dtype=np.complex128)
basis = d3.Chebyshev(coord, size=N, bounds=(0, L))

# Fields
f = dist.Field(name="f", bases=basis)
g = dist.Field(name="g", bases=basis)
omega = dist.Field(name="omega")

# Substitutions
D = lambda f: d3.Differentiate(f, coord)
lift_basis = basis.derivative_basis(1)
lift = lambda f: d3.Lift(f, lift_basis, -1)

# Tau fields
tau_f1 = dist.Field(name="tau_f1")
f1 = D(f) + lift(tau_f1)
tau_g1 = dist.Field(name="tau_g1")
g1 = D(g) + lift(tau_g1)

# Problem
problem = d3.EVP([f, g, tau_f1, tau_g1], eigenvalue=omega, namespace=locals())
problem.add_equation("1j*f1 + omega*g = 0")
problem.add_equation("1j*g1 + omega*f = 0")

# Boundary conditions
problem.add_equation("f(x=0) = 0")
problem.add_equation("f(x=L) = 0")

# Solve
solver = problem.build_solver()
solver.solve_dense(solver.subproblems[0])
evals = solver.eigenvalues.real

# Plotting; sort according to absolute value since we have both
# negative/positive eigenvalues of same magnitude.
ii = np.argsort(np.abs(evals))
x = dist.local_grid(basis)

del f, g, f1, g1

def normalize(fg, x, zero=1e-12):
    # Normalize wave function.
    a = np.sqrt(trapezoid(fg**2, x))
    if a < zero:
        return fg
    else:
        return fg/a

# Pick the ith eigenfunction in ascending order of the eigenvalues
for n, i in enumerate(ii[:5], start=1):
    solver.set_state(i, solver.subsystems[0])
    f = solver.state[0]["g"]
    fg = normalize(f, x)
    plt.plot(x, fg, label=f"n={n}")

plt.title(r"first 5 eigenmodes of a vibrating string")
plt.ylabel(r"displacement $f(x)$")
plt.xlabel(r"coordinate $x$")
plt.show()
