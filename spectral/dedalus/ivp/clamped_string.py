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

# Setup ----------------------------------------------------------------

# Parameters
L = np.pi # interval length
N = 128 # number of collocation points

# Bases
coord = d3.Coordinate("x")
dist = d3.Distributor(coord, dtype=np.float64)
basis = d3.Chebyshev(coord, size=N, bounds=(0, L))

# Fields
f = dist.Field(name="f", bases=basis) # displacement
g = dist.Field(name="g", bases=basis) # velocity

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
problem = d3.IVP([f, g, tau_f1, tau_f2], namespace=locals())
problem.add_equation("dt(f) - g = 0")
problem.add_equation("dt(g) - f2 = 0")

# Boundary conditions
problem.add_equation("f(x=0) = 0")
problem.add_equation("f(x=L) = 0")

# Initial conditions ---------------------------------------------------

x = dist.local_grid(basis)

# Approximate a Gaussian that vanishes at the ends by computing
# the amplitudes of the first 10 modes using Mathematica:
#   Integrate[Sin[n x] Sin[x] Exp[-(x - \[Pi]/2)^2], {x, 0, \[Pi]}]/(\[Pi]/2)
# ampl = np.array([0.768907, 0., -0.222695, 0., 0.00726429, 0., -0.00167352, 0., -0.000839758, 0.])
# freqs = np.arange(1, 10 + 1)
# ip = np.sum([a * np.sin(f * x) for (a, f) in zip(ampl, freqs)], axis=0)

# Problem 6-12 from A. P. French, Vibrations and Waves (1971).
# ip = np.pi/2 - np.abs(x-np.pi/2)

# A random initial profile that vanishes at the end point and generated
# by a simple moving average.
# win = 10
# ip = np.random.random(N + win - 1)
# ip = np.cumsum(y)
# ip[win:] = ip[win:] - ip[:-win]
# ip = ip[win - 1:] / win
# ip = ip * (np.sin(x) ** 0.3)

# A perturbed odd function.
eps = 0.1
ip = np.exp(-eps*x)*np.sin(2*x)

f["g"] = ip # initial profile
g["g"] = np.zeros(N) # zero initial velocity

# Solve ----------------------------------------------------------------

stop_time = 20
timestepper = d3.SBDF2
timestep = 1e-3

solver = problem.build_solver(timestepper)
solver.stop_sim_time = stop_time

while solver.proceed:
    solver.step(timestep)

    if solver.iteration % 10 == 0:
        fig, ax = plt.subplots()
        ax.set_xlim((0, np.pi))
        ax.set_ylim((-1, 1))
        # ax.plot(
        #     x,
        #     np.sum([a * np.cos(f * solver.sim_time) * np.sin(f * x) for (a, f) in zip(ampl, freqs)],
        #            axis=0),
        #     "C0",
        #     alpha=0.5)
        ax.plot(x, ip, "C0--", alpha=0.5)
        ax.plot(x, f["g"], "C3")

        plt.title("Time = {:.3f}".format(solver.sim_time))
        plt.tight_layout()
        plt.savefig("clamped_string_{:04d}.png".format(solver.iteration // 10), dpi=150)
        print("clamped_string_{:04d}.png written".format(solver.iteration // 10))
        plt.close(fig)

run(r"""ffmpeg
    -f image2
    -framerate 24
    -i clamped_string_%04d.png
    -c:v libx264
    -preset fast
    -crf 20
    -pix_fmt yuv420p
    clamped_string_4.mp4""".split())
