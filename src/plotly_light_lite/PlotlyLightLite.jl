"""
`PlotlyLightLite` is a lightweight interface to the underlying `PlotlyLight` package (Fastest time-to-first-plot in Julia!), itself an "ultra-lightweight interface" to the `Plotly` javascript libraries. `PlotlyLightLite` supports *some* of the `Plots.jl` interface for plotting. This package may be of use as an alternative to `Plots` in resource-constrained environments, such as `binder`.

# `Plots.jl` uses

* positional arguments for data
* keyword arguments for attributes
* `plot()` is a workhorse with `seriestype` indicating which plot; there are also special methods (e.g. `scatter(x,y)` becomes `plot(x,y; seriestype="scatter")`)

# `PlotlyLight.jl` uses

* `data::Vector{Config}` to hold tracts of data for plotting
* `layout::Config` to adjust layout
* `config::Config` to adjust global configurations
* `Config` very flexibly creates the underlying Javascript objects the plotly interface expects
* `Plot()` is a workhorse with `type` acting like `seriestype` and also `mode`

# `PlotlyLightLite.jl` has this dispatch for `plot`:

* merge `layout`; merge `config`; pass `kwargs` to `Config` push onto `data` or merge onto last tract:

```
plot(; layout::Config?, config::Config, kwargs...)
plot!([p::Plot]; layout::Config?, config::Config?, kwargs...)
```

* Line plot. connecting `x`,`y` (and possibly `z`). For 2D, use `!isfinite` values in `y` to break.

```
plot(x,y,[z]; kwargs...)
plot!([p::Plot], x, y, [z]; kwargs...
```

* Data can be generated from a function:

```
plot(f::Function, ab; kwargs...) => plot(unzip(f, ab)...; kwargs...)
plot(f::Function, a, b; kwargs...) => plot(unzip(f, a, b)...; kwargs...)
plot!([p::Plot], f, ab, [b])
```

* plot each function as lineplot:

```
plot(fs::Vector{Function}, a, [b]; kwargs...)
plot!([p::Plot], fs::Vector{Function}, a, [b]; kwargs...)
```

!!! note
    Currently `x`, `y` make vectors; should matrices be supported using column vectors? "In Plots.jl, every column is a series, a set of related points which form lines, surfaces, or other plotting primitives. "

* Parametric line plots, 2 or 3d

```
plot(fs::NTuple(N,Function), a, [b]; kwargs...)
plot!([p::Plot], fs::NTuple(N,Function), a, [b]; kwargs...)
```

Alternatively

```
plot(u::Function, v::Function, [w::Function], a, [b]; kwargs...)
```

In addition there are these plot constructors for higher-dimensional plots

* `contour`
* `implicit_plot`
* `heatmap`
* `surface`
* `wireframe`

There are also numerous functions to modify attributes of an existing plot.

"""
module PlotlyLightLite

import PlotlyLight
import PlotlyLight: Plot, Config

using PlotUtils


include("utils.jl")
include("plots-lite.jl")

export Plot, Config # but not Preset, preset, plot

export plot, plot!, scatter, scatter!
export contour, contour!, heatmap, heatmap!
export surface, surface!, wireframe, wireframe!
export implicit_plot, implicit_plot!
export quiver, quiver!, arrow, arrow!
export annotate, annotate!, title!, size!, legend!
export xlabel!, ylabel!, xlims!, ylims!, xaxis!, yaxis!
export rect!, circle!, hline!, vline!
export parallelogram, parallelogram!, circ3d, circ3d!, skirt, skirt!
export current

export unzip

end
