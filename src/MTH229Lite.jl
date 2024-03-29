"""
    MTH229Lite

Support files for MTH229. Unlike the `MTH229` package, this package omits `SymPy` and has a simplified plotting setup for running within resource-constrained environments, such as binder.org (e.g. [mth229lite](https://mybinder.org/v2/gh/mth229/229-projects/lite?labpath=blank-notebook.ipynb)).

Exports:
* `e` is aliased to `exp(1)`
* `rangeclamp` to restrict large `y` values; `fisheye` to change `x` axis scale; `unzip` to manipulate plotting limits
* `lim` to explore limits numerically
* `sign_chart` to explore sign changes numerically
* `bisection` and `newton` for solving `f(x) = 0`. This package also exports `Roots` which exposes `find_zero` and `find_zeros` (and their aliases `fzero` and `fzeros`).
* `tangent(f,c)` and `secant(f,a,b)` for creating tangent and secant line functions
* `riemann` a simple Riemann sum function. This package also exports `QuadGK` for real-world usage.
* The operator `'` is overloaded for functions to find the derivative using the `ForwardDiff` package. See `D` also.
* The [BinderPlots](https://jverzani.github.io/BinderPlots.jl/dev/) package provides a basic plotting interface to `PlotlyLight`.
* The [SimpleExpressions](https://jverzani.github.io/SimpleExpressions.jl/dev/) package is included to create simple expressions to use in place of functions. There is no `SymPy` package provided, as is done with `MTH229`.
"""
module MTH229Lite

using Reexport
@reexport using LinearAlgebra

@info "Loading `BinderPlots` for plotting. Also adding `plot` etc. See `?plot` for details."
include("binder_plots/BinderPlots.jl")
@reexport using .BinderPlots

@info "Loading `Roots` for solving `f(x)=0`: `fzero`, `fzeros`, etc."
@reexport using Roots
@reexport using SpecialFunctions
@info "Loading `QuadGK` for integration: `quadgk`"
@reexport using QuadGK
@info "Loading `SimpleExpressions` for using a symbolic value. No `SymPy` is available"
@reexport using SimpleExpressions
import SimpleExpressions: hassymbolic, issymbolic, free_symbol
import SimpleExpressions: AbstractSymbolic, Symbolic, SymbolicNumber, SymbolicParameter, SymbolicExpression, SymbolicEquation

@info "Loading `ForwardDiff` and overloading `f'` notation for derivatives"
using ForwardDiff

@info "See `?MTH229Lite` for more details."
export e, .., tangent, secant, fisheye, rangeclamp
export lim, bisection, newton, D, sign_chart, riemann
export plotif

include("mth229-lite.jl")
include("plot-utils.jl")
include("polynomial.jl")
include("inverse-functions.jl")
end
