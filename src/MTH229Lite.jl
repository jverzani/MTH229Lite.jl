module MTH229Lite

using Reexport
@reexport using Roots
@reexport using SpecialFunctions
@reexport using QuadGK
@reexport using LinearAlgebra
#@reexport using SimpleExpressions
@reexport using PlotlyLight

using PlotUtils
using ForwardDiff

export e, tangent, secant, fisheye, rangeclamp
export bisection, newton, sign_chart, riemann
export plot, plot!, scatter, scatter!, annotate, annotate!, title!, size!, xlims!, ylims!
export plotif

include("mth229-lite.jl")
include("plot-utils.jl")
include("plots-lite.jl")

end
