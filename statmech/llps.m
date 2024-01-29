(*  Liquid-liquid phase separation using Flory-Huggins theory.

      created  2023-12-18 21:45 IST
     modified  2023-12-18 21:45 IST

    This file contains a bunch of basic functions for common tangent
    construction and finding binodal curves.  My primary goal was to
    reproduce the results of  Wei et al., Phys. Rev. Lett. 125, 268001
    (2020).  *)

(* === Basic definitions === *)

Options[nearlyEqual] = {"AbsTolerance" -> 10^-10,
                        "RelTolerance" -> 10^-15};

(* Function equivalent to NumPy's allclose. *)
nearlyEqual[x:_?NumericQ, y:_?NumericQ, OptionsPattern[]] :=
  Module[{a = Chop[x], b = Chop[y]},
    Abs[a - b] <= OptionValue["AbsTolerance"] + OptionValue["RelTolerance"]*Abs[b]
  ];

(* Flory-Huggins free energy per lattice. *)
fhFree[phi_, n_:1, c_:1, units_:1] :=
  units * ( phi*Log[phi]/n + (1 - phi)*Log[1 - phi] + c*phi*(1 - phi) );

(* Chemical potential. *)
fhMu[phi_, n_:1, c_:1, units_:1] :=
  units * ( (1 + Log[phi])/n - (1 + Log[1 - phi]) + c*(1 - 2*phi) );

(* Osmotic pressure. *)
fhPi[phi_, n_, c_, units_:1] :=
  units * ( phi*(n - 1 + n*c*phi)/n + Log[1 - phi] );

(*  The goal of the scaling function is to scale the interval [0, 1] ->
    [0, ∞].  This way, we can search over a wider range of φ values
    while looking for roots.  *)
scale[x_, eps_:10^-15] := Tanh[eps*x];
scaleInv[x_, eps_:10^-15] := ArcTanh[x]/eps;

(* === Binodal concentrations === *)

Options[binodalPhi] = {"rootDelta" -> 10^-2,   (* minimum difference between roots *)
                       "epsMin" -> 10^-15,     (* smallest eps to use *)
                       "epsMax" -> 1,          (* largest eps to use *)
                       "phiLHS" -> 1,          (* starting value of scaled vf of dilute phase *)
                       "phiRHS" -> 20};        (* starting value of scaled vf of dense phase *)

binodalPhi[n:_?NumericQ, c:_?NumericQ, dP:_?NumericQ:0.0, OptionsPattern[]] :=
  Module[{roots = {Null, Null}, eps},
    (*  Proceed to refine the roots if the roots aren't separated enough or if
        they are imaginary.  But make sure that the stretching parameter
        epsilon (eps) is not too small.

        Anecdote: it took me longer than I'd like to admit to fully figure this
        out, and I'm not entirely sure everything is quite right.  Choosing
        a largish (~ 1) value of epsilon seems to create problems close to the
        critical point χ_c.  But for large χ, we need to make epsilon smaller
        (~ 10^-10 or smaller).  But that still leaves out one question:
        should we go from small epsilon to large, or vice versa?  In my
        numerical experiments, I saw that going from small to large can
        create problems for large χ, so we're doing the opposite here.  *)
    eps = OptionValue["epsMin"];
    While[(Abs[roots[[1]] - roots[[2]]] < OptionValue["rootDelta"]
            || !AllTrue[roots, RealValuedNumericQ]) && eps <= OptionValue["epsMax"],
      roots = Quiet@Check[
                FindRoot[{ fhMu[scale[phi1, eps], n, c] == fhMu[scale[phi2, eps], n, c],
                           fhPi[scale[phi1, eps], n, c]  - fhPi[scale[phi2, eps], n, c] == dP },
                         {phi1, OptionValue["phiLHS"]},
                         {phi2, OptionValue["phiRHS"]/eps},
                         Method->"Newton",
                         WorkingPrecision->100,
                         MaxIterations->500],
                $Failed,
                {FindRoot::cmvit, FindRoot::jsing}
              ];

      (*  Error implies root must be kept as null.  *)
      If[FreeQ[roots, $Failed],
         roots = Chop@{scale[phi1, eps], scale[phi2, eps]} /. roots,
         roots = {Null, Null}];

      eps *= 10;
    ];

    (*  Note that when Newton's method is used, sometimes FindRoot[] can
        get stuck at a minimum without solving the equations.  But this
        is not reported as failure.  Thus, make sure that the roots we've
        found solve the equations properly.  If they don't, then return
        a null value.  *)
    If[!AllTrue[roots, RealValuedNumericQ] ||
      Abs[roots[[1]] - roots[[2]]] < OptionValue["rootDelta"] ||
      !nearlyEqual[fhMu[roots[[1]], n, c], fhMu[roots[[2]], n, c]] ||
      !nearlyEqual[fhPi[roots[[1]], n, c] - fhPi[roots[[2]], n, c], dP],
      roots = {Null, Null}];
    roots
  ];

(* === Common tangent plot === *)

tangentPlot[n:_?NumericQ:1.0, c:_?NumericQ:1.0, dP:_?NumericQ:0.0] :=
  Module[{phi1, phi2},
    {phi1, phi2} = binodalPhi[n, c, dP];
    Plot[{fhFree[phi, n, c],
          fhMu[phi1, n, c]*phi + fhPi[phi1, n, c],
          fhMu[phi2, n, c]*phi + fhPi[phi2, n, c]},
      {phi, 0, 1},
      Mesh->{{phi1, phi2}},
      MeshStyle->PointSize[Large]]
  ];

(* === Binodal === *)

(* cmvit, jsing *)
Options[binodal] = {"NumPoints" -> 10,
                    "FudgeFactor" -> 0.05};

binodal[n:_?NumericQ:1.0, cMax:_?NumericQ:1.0, dP:_?NumericQ:0.0, OptionsPattern[]] :=
  Module[{cCrit,
          cDiff,
          cList,
          fudge = Abs[OptionValue["FudgeFactor"]],
          data},
    (*  First compute the usual critical χ and use that to compute the
        χ increment.  *)
    cCrit = 0.5*(1 + 1/Sqrt[n])^2;
    cDiff = (cMax - cCrit)/OptionValue["NumPoints"];

    (*  Fudge the guessed critical value a bit so that we are above the
        critical value.  *)
    If[fudge > 10^-10,
       cCrit = Ceiling[cCrit*(1 + fudge), fudge]];

    cList = Range[cCrit, cMax, cDiff];
    phiList = (binodalPhi[n, #, dP])& /@ cList;
    data = Transpose@{phiList[[All, 1]], cList} ~Join~
      Transpose@{phiList[[All, 2]], cList};
    data = Sort[data];
    data
  ];
