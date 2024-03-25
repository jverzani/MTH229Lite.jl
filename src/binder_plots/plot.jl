## ----
## plot has many different interfaces for dispatch
##


## ---


"""
    plot(x, y, [z]; [linecolor], [linewidth], [legend], kwargs...)
    plot(f::Function, a, [b]; kwargs...)
    plot(pts; kwargs...)

Create a line plot.

Returns a `Plot` instance from [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl)

* `x`,`y` points to plot. NaN values in `y` break the line. Can be specified through a container, `pts` of ``(x,y)`` or ``(x,y,z)`` values.
* `a`, `b`: the interval to plot a function over can be given by two numbers or if just `a` then by `extrema(a)`.
* `linecolor`: color of line
* `linewidth`: width of line
* `label` in legend

Other keyword arguments include `size=(width=X, height=Y)`, `xlims` and `ylims`, `legend`, `aspect_ratio`.

Provides an interface like `Plots.plot` for plotting a function `f` using `PlotlyLight`. This just scratches the surface, but `PlotlyLight` allows full access to the underlying `JavaScript` [library](https://plotly.com/javascript/) library.

The provided "`Plots`-like" functions are [`plot`](@ref), [`plot!`](@ref), [`scatter!`](@ref), `scatter`, [`annotate!`](@ref),  [`title!`](@ref), [`xlims!`](@ref) and [`ylims!`](@ref).

# Example

```
p = plot(sin, 0, 2pi; legend=false)
plot!(cos)
# add points
x0 = [pi/4, 5pi/4]
scatter!(x0, sin.(x0), markersize=10)
# add text
annotate!(tuple(zip(x0, sin.(x0), ("A", "B"))...), halign="left", pointsize=12)
title!("Sine and cosine and where they intersect in [0,2π]")
# adjust limits
ylims!((-3/2, 3/2))
# add shape
y0, y1 = extrema(p).y
[rect!(xᵢ-0.1, xᵢ+0.1, y0, y1, fillcolor="gray", opacity=0.2) for xᵢ ∈ x0]
# display plot
p
```

!!! note "Warning"
    You may need to run the first plot cell twice to see an image.
"""
function plot(x, y, zs...; kwargs...)
    p = _new_plot(; kwargs...)
    plot!(p, x, y, zs...; kwargs...)
    p
end

function plot(f::Function, a::Real, b::Real;
              kwargs...)
    p = _new_plot(;kwargs...)
    plot!(p, f, a, b; kwargs...)
    p
end

# ab is some interval specification via `extrema`
plot(f::Function, ab; kwargs...) = plot(f, extrema(ab)...; kwargs...)
# default
plot(f::Function; kwargs...) = plot(f, -5, 5; kwargs...)

# makie style
plot(pts; kwargs...) = plot(unzip(pts)...; kwargs...)

"""
    plot!([p::Plot], x, y; kwargs...)
    plot!([p::Plot], f, a, [b]; kwargs...)
    plot!([p::Plot], f; kwargs...)

Used to add a new tract to an existing plot. Like `Plots.plot!`. See [`plot`](@ref) for argument details.
"""
function plot!(p::Plot, x, y;
               label = nothing,
               kwargs...)

    # fussiness to handle NaNs in `y` values
    y′ = [isfinite(yᵢ) ? yᵢ : nothing for yᵢ ∈ y]
    _push_line_trace!(p, x, y′; label, kwargs...)
    p
end

plot!(pts; kwargs...) = plot!(current_plot[], pts; kwargs...)
plot!(p::Plot, pts; kwargs...) = plot!(p, unzip(pts)...; kwargs...)

# pass through to Javascript; like Plot...
plot!(; kwargs...) = plot!(current_plot[]; kwargs...)
function plot!(p::Plot; layout::Union{Nothing, Config}=nothing,
               config::Union{Nothing, Config}=nothing,
               kwargs...)
    !isnothing(layout) && merge!(p.layout, layout)
    !isnothing(config) && merge!(p.config, config)
    d = Config(kwargs...)
    !isempty(d) && push!(p.data, d)
    p
end

# XXX not clean what is line=... and what is data
function _push_line_trace!(p, x, y;
                           mode="lines",
                           fill=nothing,
                           label = nothing, kwargs...
                           )
    c = Config(; x, y, mode=mode)
    _merge!(c; name=label, fill)
    kws = _linestyle!(c.line; kwargs...)
    _merge!(c; kws...)
    push!(p.data, c)
end

plot!(x, y, z; kwargs...) = plot!(current_plot[], x, y, z; kwargs...)
function plot!(p::Plot, x, y, z;
               label = nothing,
               center=nothing, up=nothing, eye=nothing,
               kwargs...)

    # XXX handle NaNs...
    c = Config(;x,y,z,type="scatter3d", mode="lines")
    _merge!(c; name=label)
    _camera_position!(p.layout.scene.camera; center, up, eye)
    kws = _linestyle!(c.line; kwargs...)
    _merge!(c; kws...)
    push!(p.data, c)
    p
end


function plot!(p::Plot, f::Function, a, b; kwargs...)
    x, y = unzip(f, a, b)
    plot!(p, x, y; kwargs...)
end

plot!(p::Plot, f::Function, ab; kwargs...) =
    plot!(p, f, extrema(ab)...; kwargs...)

function plot!(p::Plot, f::Function; kwargs...)
    m, M = extrema(p).x
    m < M || throw(ArgumentError("Can't identify interval to plot over"))
    plot!(p, f, m, M; kwargs...)
end

plot!(x, y; kwargs...) =  plot!(current_plot[], x, y; kwargs...)
plot!(f::Function, args...; kwargs...) =  plot!(current_plot[], f, args...; kwargs...)

# convenience to make multiple plots by passing in vector
# using plot! allows line customizations...
plot(fs::Vector{<:Function}; kwargs...) = plot(fs, -5,5; kwargs...)
plot(fs::Vector{<:Function}, ab; kwargs...) = plot(fs, extrema(ab)...; kwargs...)
function plot(fs::Vector{<:Function}, a, b;
              label = nothing,
              linecolor = nothing, # string, symbol, RGB?
              linewidth = nothing, # pixels
              linestyle = nothing, # solid, dot, dashdot,
              lineshape = nothing,
              kwargs...)
    u, vs... = fs

    la = Recycler(label)
    lc, lw, ls, lsh = Recycler.((linecolor, linewidth, linestyle, lineshape))
    p = plot(u, a, b;
             label=la[1],
             linecolor=lc[1], linewidth=lw[1],
             linesstyle=ls[1], lineshape=lsh[1],
             kwargs...)
    for (j,v) ∈ enumerate(vs)
        i = j + 1
        plot!(p, v, a, b;
              label=la[i],
              linecolor=lc[i], linewidth=lw[i],
              linesstyle=ls[i], lineshape=lsh[i],
              kwargs...
              )
    end
    p
end

# 2-3
"""
    plot((f,g), a, b; kwargs...)
    plot!([p::Plot], (f,g), a, b; kwargs...)

Make parametric plot from tuple of functions, `f` and `g`.
"""
function plot(uv::NTuple{N,Function}, a, b=nothing; kwargs...) where {N}
    2 <= N <= 3 || throw(ArgumentError("2 or 3 functions only"))
    p = _new_plot(; kwargs...)
    plot!(p, uv, a, b, kwargs...)
end

# Plots interface is 2/3 functions, not a tuple.
plot(u::Function, v::Function, w::Function, args...; kwargs...) =
    plot((u,v, w), args...; kwargs...)

plot(u::Function, v::Function, args...; kwargs...) =
    plot((u,v), args...; kwargs...)

plot!(uv::Tuple{Function, Function}, a, b=nothing; kwargs...) =
    plot!(current_plot[], us, a, b; kwargs...)

function plot!(p::Plot, uv::NTuple{N,Function}, a, b=nothing; kwargs...) where {N}
    2 <= N <= 3 || throw(ArgumentError("2 or 3 functions only"))

    # which points to use?
    if isnothing(b)
        t = range(extrema(a)...; length=251)
    else
        t = range(a, b; length=251)
    end

    plot!(p, (fᵢ.(t) for fᵢ ∈ uv)...; kwargs...)
end



## --- This is `plot` from PlotlyLight
# No default, see below
#plot(; kw...) = plot(get(kw, :type, :scatter); kw...)

Base.propertynames(::typeof(plot)) = sort!(collect(keys(PlotlyLight.schema.traces)))
Base.getproperty(::typeof(plot), x::Symbol) = (; kw...) -> plot(x; kw...)

function plot(trace::Symbol; kw...)
    PlotlyLight.check_attributes(trace; kw...)
    plot(; type=trace, kw...)
end

"""
    plot(; layout::Config?, config::Config?, kwargs...)

Pass keyword arguments through `Config` and onto `PlotlyLight.Plot`.
"""
function plot(; layout::Union{Nothing, Config}=nothing,
              config::Union{Nothing, Config}=nothing,
              size=(width=800, height=600),
              xlims=nothing, ylims=nothing,
              legend=nothing,
              aspect_ratio = nothing,
              kwargs...)
    p = _new_plot(;size, xlims, ylims, legend, aspect_ratio)
    plot!(p; layout, config, kwargs...)
    p
end
