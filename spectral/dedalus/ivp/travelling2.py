# -*- coding: utf-8 -*-
"""Initial value problem for string waves.

Solves the IVP for string waves on a string clamped in the interval
[0, pi].  The eigenvalues in this case are 1, 2, 3, ... and the
eigenmodes are sin(x), sin(2x), sin(3x), ...
"""

import numpy as np
import matplotlib.pyplot as plt
import dedalus.public as d3
from subprocess import run

# Parameters
L = 10 # interval length
N = 512 # number of collocation points
c =0.1

stop_time = 30
timestepper = d3.SBDF2
timestep = 1e-3

# Bases
coord = d3.Coordinate("x")
dist = d3.Distributor(coord, dtype=np.float64)
basis = d3.Chebyshev(coord, size=N, bounds=(-L/2, L/2))

# Fields
f = dist.Field(name="f", bases=basis) # displacement
g = dist.Field(name="g", bases=basis) # velocity

# Substitutions
D = lambda f: d3.Differentiate(f, coord)
#f2 = D(D(f))Cos[x - t]
lift_basis = basis.derivative_basis(1)
lift = lambda f: d3.Lift(f, lift_basis, -1)

# Tau fields
tau_f1 = dist.Field(name="tau_f1")
f1 = D(f) + lift(tau_f1)
tau_f2 = dist.Field(name="tau_f2")
f2 = D(f1) + lift(tau_f2)

# Problem
problem = d3.IVP([f, g], namespace=locals())
problem.add_equation("dt(f) - g = 0")
problem.add_equation("dt(g) - c**2*D(D(f)) = 0")

# Boundary conditions
# problem.add_equation("f(x=L/2) = 0")
# problem.add_equation("f(x=-L/2) = 0")

# Initial conditions
x = dist.local_grid(basis)

# Approximate a Gaussian that vanishes at the ends by computing
# the amplitudes of the first 10 modes using Mathematica:
#   Integrate[Sin[n x] Sin[x] Exp[-(x - \[Pi]/2)^2], {x, 0, \[Pi]}]/(\[Pi]/2)
# ampl = np.array([0.768907, 0., -0.222695, 0., 0.00726429, 0., -0.00167352, 0., -0.000839758, 0.])
# freqs = np.arange(1, 10 + 1)
beta = 10
f["g"] = np.exp(-beta*x**2/2)
f["g"] -= f["g"][0]

# Zero initial velocity
g["g"] = np.zeros(N)

# Solve
solver = problem.build_solver(timestepper)
solver.stop_sim_time = stop_time

plt.plot(x, f["g"])
plt.show()

while solver.proceed:
    solver.step(timestep)

    if solver.iteration % 10000 == 0:
        print(solver.iteration)
        plt.plot(x, f["g"])
        plt.show()

plt.ylim(-2, 2)
plt.show()
