"""
    MTH229Lite

Support files for MTH229. Unlike the `MTH229` package, this omits `SymPy` and has a simplified plotting setup for running within resource constrained environments, such as binder.org.

Exports:
* `e` aliased to `exp(1)`
* `tangent(f,c)` and `secant(f,a,b)` for creating tangent and secant line functions
* `rangeclamp` to restrict large `y` values; `fisheye` to change `x` axis scale
* `lim` to explore limits numerically
* `sign_chart` to explore sign changes numerically
* `riemann` a simple Riemann sum function. This package also exports `QuadGK`.
* `bisection` and `newton` for solving `f(x) = 0`. This package also exports `Roots` which exposes `find_zero` and `find_zeros` (and their aliases`fzero`, `fzeros`).
* The operator `'` is overloaded for functions to find the derivative using the `FowardDiff` package
* The `SimpleExpressions` package is included to create simple expressions to use in place of functions. There is no `SymPy` package provided, as is done with `MTH229`.
* The `plot` and `plot!` functions provided are modeled after those in `Plots.jl` but utilize `PlotlyLight` as a plotting backend, as it requires far fewer resources than `Plots`. See the docstring for [`plot`](@ref) for an example.
"""
module MTH229Lite

using Reexport
@reexport using LinearAlgebra

@info "Loading PlotlyLight for plotting. Also adding `plot` etc."
@reexport using PlotlyLight
@info "Loading Roots for solve f(x)=0: `fzero`, `fzeros`, etc."
@reexport using Roots
@reexport using SpecialFunctions
@info "Loading QuadGK for integration: `quadgk`
@reexport using QuadGK
@info "Loading SimpleExpressions for using a symbolic value. No SymPy is available"
@reexport using SimpleExpressions

using PlotUtils

@info "Loading ForwardDIff and overloading `f'` notation for derivatives"
using ForwardDiff

export e, tangent, secant, fisheye, rangeclamp
export lim, bisection, newton, sign_chart, riemann
export plot, plot!, scatter, scatter!, annotate, annotate!, title!, size!, xlims!, ylims!
export unzip, plotif

include("mth229-lite.jl")
include("plot-utils.jl")
include("plots-lite.jl")

end
