# -*- coding: utf-8 -*-

import numpy as np
import matplotlib.pyplot as plt
import dedalus.public as d3

# Parameters
L = np.pi    # interval length
N = 128    # number of collocation points

# Bases
coord = d3.Coordinate("x")
dist = d3.Distributor(coord, dtype=np.float64)
basis = d3.Chebyshev(coord, size=N, bounds=(0, L))

# Fields
f = dist.Field(name="f", bases=basis)
g = dist.Field(name="g", bases=basis)
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

tau_g1 = dist.Field(name="tau_g1")
g1 = D(g) + lift(tau_g1)
tau_g2 = dist.Field(name="tau_g2")
g2 = D(g1) + lift(tau_g2)

# Problem
problem = d3.EVP([f, g, tau_f1, tau_f2, tau_g1, tau_g2], eigenvalue=omega2, namespace=locals())
problem.add_equation("4*f2 + omega2*f = 0")
problem.add_equation("9*g2 + omega2*g = 0")

# Boundary conditions
problem.add_equation("f(x=0) = 0")
problem.add_equation("f(x=L) = 0")
problem.add_equation("g(x=0) = 0")
problem.add_equation("g(x=L) = 0")

# Solve
solver = problem.build_solver()
solver.solve_dense(solver.subproblems[0])
evals = np.sqrt(np.sort(solver.eigenvalues).real)

print(evals[:16])
