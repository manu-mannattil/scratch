# -*- coding: utf-8 -*-
"""Eigenmodes of a string (with eigenvalue filtering).

This script finds the eigenmodes of a string clamped in the interval [0,
pi] and described by the standard equation:

    d^2f/dx^2 + omega^2 * f = 0

The eigenvalues are 1, 2, 3, ...
"""

import numpy as np
import matplotlib.pyplot as plt
import dedalus.public as d3

class StringModes:
    """
    Parameters
    ----------
    eps : float
        scale factor
    L : float
        interval length
    N : int
        number of collocation points
    """
    def __init__(self, L=np.pi, eps=1, N=128):
        self.L = np.pi
        self.eps = eps
        self.N = 128

    def solve_evp_N(self, N):
        eps, L = self.eps, self.L
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
        problem.add_equation("eps**2*f2 + omega2*f = 0")

        # Boundary conditions
        problem.add_equation("f(x=0) = 0")
        problem.add_equation("f(x=L) = 0")

        # Solve
        solver = problem.build_solver()
        solver.solve_dense(solver.subproblems[0])

        evals = solver.eigenvalues
        evecs = []

        for i in range(len(evals)):
            solver.set_state(i, solver.subsystems[0])
            fg = np.copy(solver.state[0]["g"])
            evecs.append(fg)

        x = dist.local_grid(basis)
        return x, evals, np.array(evecs)

    def solve(self, clean=True, clean_factor=1.5):
        x, evals_low, evecs_low = self.solve_evp_N(self.N)

        if clean:
            _, evals_hi, evecs_hi = self.solve_evp_N(int(clean_factor*self.N))

            cleaner = FilterEigenvalues(evals_low, evals_hi)
            evals, indx = cleaner.clean()
        else:
            indx = np.argsort(evals_low.real)
            evals = evals_low[indx]

        return x, np.sqrt(evals.real), evecs_low[indx]

class FilterEigenvalues:
    """Adapted from eigentools.py from Dedalus v2 [1].

    [1]: https://github.com/DedalusProject/eigentools/blob/4310620cddd4a4348950e7352ac3e163cd9468bd/eigentools/eigenproblem.py
    """

    def __init__(self, evals_low, evals_hi):
        self.evals_low = evals_low
        self.evals_hi = evals_hi

        self.delta_ordinal = None
        self.delta_near = None
        self.drift_threshold = None
        self.cleaned = True

    def clean(self, drift_threshold=1e6, use_ordinal=False):
        """Clean the eigenvalues.

        Compares the eigenvalues obtained at two different resolutions.
        Returns trustworthy eigenvalues using nearest delta, (see section
        7.5 of Boyd's book).
        """
        self.drift_threshold = drift_threshold

        evals_low = self.evals_low
        evals_hi = self.evals_hi

        # Reverse engineer correct indices to make unsorted list from sorted.
        reverse_evals_low_indx = np.arange(len(evals_low))
        reverse_evals_hi_indx = np.arange(len(evals_hi))

        evals_low_and_indx = np.asarray(list(zip(evals_low, reverse_evals_low_indx)))
        evals_hi_and_indx = np.asarray(list(zip(evals_hi, reverse_evals_hi_indx)))

        # Remove NaNs
        evals_low_and_indx = evals_low_and_indx[np.isfinite(evals_low)]
        evals_hi_and_indx = evals_hi_and_indx[np.isfinite(evals_hi)]

        # Sort evals_low and evals_hi by real parts.
        evals_low_and_indx = evals_low_and_indx[np.argsort(evals_low_and_indx[:, 0].real)]
        evals_hi_and_indx = evals_hi_and_indx[np.argsort(evals_hi_and_indx[:, 0].real)]

        evals_low_sorted = evals_low_and_indx[:, 0]
        evals_hi_sorted = evals_hi_and_indx[:, 0]

        # Compute sigmas from lower resolution run.
        sigmas = np.zeros(len(evals_low_sorted))
        sigmas[0] = np.abs(evals_low_sorted[0] - evals_low_sorted[1])
        sigmas[1:-1] = [
            0.5 * (np.abs(evals_low_sorted[j] - evals_low_sorted[j - 1]) +
                   np.abs(evals_low_sorted[j + 1] - evals_low_sorted[j]))
            for j in range(1, len(evals_low_sorted) - 1)
        ]
        sigmas[-1] = np.abs(evals_low_sorted[-2] - evals_low_sorted[-1])

        if not (np.isfinite(sigmas)).all():
            logger.warning(
                "At least one eigenvalue spacings (sigmas) is non-finite (np.inf or np.nan)!")

        # Ordinal delta.
        self.delta_ordinal = np.array([
            np.abs(evals_low_sorted[j] - evals_hi_sorted[j]) / sigmas[j]
            for j in range(len(evals_low_sorted))
        ])

        # Nearest delta.
        self.delta_near = np.array([
            np.nanmin(np.abs(evals_low_sorted[j] - evals_hi_sorted) / sigmas[j])
            for j in range(len(evals_low_sorted))
        ])

        # Discard eigenvalues with 1/delta_near < drift_threshold.
        if use_ordinal:
            inverse_drift = 1 / self.delta_ordinal
        else:
            inverse_drift = 1 / self.delta_near
        evals_low_and_indx = evals_low_and_indx[np.where(inverse_drift > self.drift_threshold)]

        evals_low = evals_low_and_indx[:, 0]
        indx = evals_low_and_indx[:, 1].real.astype(np.int32)

        self.cleaned = True
        return evals_low, indx

    def plot_drift(self, axes=None):
        """Plot drift ratios (both ordinal and nearest) vs. mode number.

        The drift ratios give a measure of how good a given eigenmode is;
        this can help set thresholds.
        """
        if self.cleaned is False:
            raise NotImplementedError(
                "Can't plot drift ratios unless eigenvalues have been cleaned.")

        if axes is None:
            fig = plt.figure()
            ax = fig.add_subplot(111)
        else:
            ax = axes
            fig = axes.figure

        mode_numbers = np.arange(len(self.delta_near))
        ax.semilogy(mode_numbers, 1 / self.delta_near, "o", alpha=0.5)
        ax.semilogy(mode_numbers, 1 / self.delta_ordinal, "x", alpha=0.5)

        ax.set_prop_cycle(None)
        good_near = 1 / self.delta_near > self.drift_threshold
        good_ordinal = 1 / self.delta_ordinal > self.drift_threshold
        ax.semilogy(mode_numbers[good_near], 1 / self.delta_near[good_near], "o", label="nearest")
        ax.semilogy(mode_numbers[good_ordinal],
                    1 / self.delta_ordinal[good_ordinal],
                    "x",
                    label="ordinal")
        ax.axhline(self.drift_threshold, alpha=0.5, color="black")
        ax.set_xlabel("mode number")
        ax.set_ylabel(r"$1/\delta$")
        ax.legend()

        return ax

s = StringModes()
x, evals, evecs = s.solve()
print(len(evals))

for i in range(5):
    plt.plot(x, evecs[i])

plt.title(r"first 5 eigenmodes of a vibrating string")
plt.ylabel(r"displacement $f(x)$")
plt.xlabel(r"coordinate $x$")
plt.show()
