# -*- coding: utf-8 -*-
"""Eigenmodes of a string.

Find the eigenmodes of a string clamped in the interval [0, pi] and
described by the standard equation:

    d^2f/dx^2 + omega^2 * f = 0

The eigenvalues are 1, 2, 3, ...
"""

import numpy as np
import matplotlib.pyplot as plt
import dedalus.public as d3

# Parameters
L = np.pi # interval length
N = 128 # number of collocation points

# Bases
coord = d3.Coordinate("x")
dist = d3.Distributor(coord, dtype=np.float64)
basis = d3.Chebyshev(coord, size=N, bounds=(0, L))

# Fields
f = dist.Field(name="f", bases=basis)
omega2 = dist.Field(name="omega2")

# Substitutions
D = lambda f: d3.Differentiate(f, coord)
lift_basis = basis.derivative_basis(1)
lift = lambda f: d3.Lift(f, lift_basis, -1)

# Tau fields
tau_f1 = dist.Field(name="tau_f1")
f1 = D(f) + lift(tau_f1)
tau_f2 = dist.Field(name="tau_f2")
f2 = D(f1) + lift(tau_f2)

# Problem
problem = d3.EVP([f, tau_f1, tau_f2], eigenvalue=omega2, namespace=locals())
problem.add_equation("f2 + omega2*f = 0")

# Boundary conditions
problem.add_equation("f(x=0) = 0")
problem.add_equation("f(x=L) = 0")

# Solve
solver = problem.build_solver()
solver.solve_dense(solver.subproblems[0])
evals = np.sqrt(solver.eigenvalues.real)

# Plot
x = dist.local_grid(basis)
ii = np.argsort(evals)

# Pick the ith eigenfunction in ascending order of the eigenvalues
for n, i in enumerate(ii[:5], start=1):
    solver.set_state(i, solver.subsystems[0])
    fg = f["g"] # coordinates on grid
    plt.plot(x, fg, label=f"n={n}")

plt.title(r"first 5 eigenmodes of a vibrating string")
plt.ylabel(r"displacement $f(x)$")
plt.xlabel(r"coordinate $x$")
plt.show()
