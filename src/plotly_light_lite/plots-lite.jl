## --- plotting

## utils
const current_plot = Ref{Plot}() # store current plot
const first_plot = Ref{Bool}(true) # for first plot warning

"""
    current()

Get current figure. A `Plot` object of `PlotlyLight`; `UndefRefError` if none.

Not typically needed, as it is implicit in most mutating calls, though may be convenient if those happen within a loop.

"""
current() = current_plot[]

# make a new plot by calling `PlotlyLight.Plot`
function _new_plot(;
                   width=800, height=600,
                   xlims=nothing, ylims=nothing,
                   legend = nothing,
                   aspect_ratio=nothing,
                   kwargs...)
    p = Plot(Config[],
             Config(), # layout
             Config(responsive=true) ) # config
    current_plot[] = p

    if first_plot[]
        @info "For the first plot, you may need to re-run your command to see the plot"
        first_plot[] = false
    end

    size!(p, width=width, height=height)
    xlims!(p, xlims)
    ylims!(p, ylims)

    # layout
    legend!(p, legend)
    aspect_ratio == :equal && (p.layout.yaxis.scaleanchor="x")

    p
end


## ----
## plot has many different interfaces for dispatch
"""
    plot(x, y, [z]; [linecolor], [linewidth], [legend], kwargs...)
    plot(f::Function, a, [b]; kwargs...)

Create a line plot.

Returns a `Plot` instance from [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl)

* `x`,`y` points to plot. NaN values in `y` break the line
* `a`, `b`: the interval to plot a function over can be given by two numbers or if just `a` then by `extrema(a)`.
* `linecolor`: color of line
* `linewidth`: width of line
* `label` in legend

Other keyword arguments include `width` and `height`, `xlims` and `ylims`, `legend`, `aspect_ratio`.

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
function plot(x, ys...; kwargs...)
    p = _new_plot(; kwargs...)
    plot!(p, x, ys...; kwargs...)
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

"""
    plot(; layout::Config?, config::Config?, kwargs...)

Pass keyword arguments through `Config` and onto `PlotlyLight.Plot`.
"""
function plot(; layout::Union{Nothing, Config}=nothing,
              config::Union{Nothing, Config}=nothing,
              width=800, height=600,
              xlims=nothing, ylims=nothing,
              legend=nothing,
              aspect_ratio = nothing,
              kwargs...)
    p = _new_plot(;width, height,xlims, ylims, legend, aspect_ratio)
    plot!(p; layout, config, kwargs...)
    p
end



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
    _linestyle!(c; kwargs...)
    _merge!(c; name=label, fill)
    _merge!(c; kwargs...)
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
    _linestyle!(c; kwargs...)
    push!(p.data, c)
    p
end

function plot!(p::Plot, x; type=nothing, mode=nothing, kwargs...)
    c = Config(;x)
    _merge!(c, type=type, mode=mode)
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
              linecolor = nothing, # string, symbol, RGB?
              linewidth = nothing, # pixels
              linestyle = nothing, # solid, dot, dashdot,
              lineshape = nothing,
              kwargs...)
    u, vs... = fs

    lc, lw, ls, lsh = Recycler.((linecolor, linewidth, linestyle, lineshape))
    p = plot(u, a, b;
             linecolor=lc[1], linewidth=lw[1],
             linesstyle=ls[1], lineshape=lsh[1],
             kwargs...)
    for (i,v) ∈ enumerate(vs)
        plot!(p, v, a, b;
              linecolor=lc[i], linewidth=lw[i],
              linesstyle=ls[i], lineshape=lsh[i],
              kwargs...
              )
    end
    p
end

"""
    scatter(x, y, [z]; [markershape], [markercolor], [markersize], kwargs...)
    scatter!([p::Plot], x, y, [z]; kwargs...)

Place point on a plot.
* `markershape`: shape, e.g. "diamond" or "diamond-open"
* `markercolor`: color e.g. "red"
* `markersize`:  size, as an integer
"""
function scatter!(p::Plot, x, y; kwargs...)

    # skip NaN or Inf
    keep_x = findall(isfinite, x)
    keep_y = findall(isfinite, y)
    idx = intersect(keep_x, keep_y)

    cfg = Config(;x=x[idx], y=y[idx], mode="markers", type="scatter")
    _markerstyle!(cfg; kwargs...)

    push!(p.data, cfg)

    p
end

function scatter!(p::Plot, x, y, z;
                  legend=nothing,
                  kwargs...)

    # skip NaN or Inf
    keep_x = findall(isfinite, x)
    keep_y = findall(isfinite, y)
    keep_z = findall(isfinite, z)
    idx = intersect(keep_x, keep_y, keep_z)

    cfg = Config(;x=x[idx], y=y[idx], z=z[idx],
                 mode="markers", type="scatter3d")
    _markerstyle!(cfg; kwargs...)

    push!(p.data, cfg)

    p
end

scatter!(x, y; kwargs...) = scatter!(current_plot[], x, y; kwargs...)

"`scatter(x, y; kwargs...)` see [`scatter!`](@ref)"
function scatter(x, ys...; kwargs...)
    p = _new_plot(; kwargs...)

    scatter!(p, x, ys...; kwargs...)
    p
end

## ----- 2-3 d plots

"""
    plot((f,g), a, b; kwargs...)
    plot!([p::PLot], (f,g), a, b; kwargs...)

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

# layout
# plots has plot(p1,p2, ...; layout=(m,n))
# makie has [p1 p2; ...] display layout
# this is in between
function plot(ps::Array{<:Plot, N}; kwargs...) where {N}
    1 <= N <= 2 || throw(ArgumentError("1 or 2 dimensional arrays only"))
    grid_layout(ps; kwargs...)
end


# special cases of plots
_adjust_matrix(m::Matrix) = collect(eachrow(m))
_adjust_matrix(x::Any) = x
"""
    contour(x, y, z; kwargs...)
    contour!([p::Plot], x, y, z; kwargs...)
    contour(x, y, f::Function; kwargs...)
    contour!(x, y, f::Function; kwargs...)

Create contour function of `f`
"""
function contour(x, y, z; kwargs...)
    p = _new_plot(; kwargs...)
    contour!(p, x, y, z; kwargs...)
end

contour(x, y, f::Function; kwargs...) =
    contour(x,y, f.(x', y); kwargs...)

contour!(x, y, z; kwargs...) =
    contour!(current_plot[], x, y, z; kwargs...)
contour!(x, y, f::Function; kwargs...) =
    contour!(current_plot[], x, y, f.(x', y); kwargs...)

## XXX might have more options *if* used Contours and did this manually
function contour!(p::Plot, x, y, z;
                  levels = nothing, # a number or something w/ step method
                  color = nothing, # scale or single color
                  colorbar::Union{Nothing, Bool} = nothing, # show colorbar
                  fill::Bool = false,
                  contour_labels::Bool = false,
                  linewidth = nothing,
                  kwargs...)

    x, y, z = _adjust_matrix.((x,y,z))
    c = Config(;x,y,z,type="contour")
    c.contours = Config()
    c.line = Config()
    _merge!(c; kwargs...)


    # color --> colorscale A symbol or name (or container)
    # levels
    !fill && (c.contours.coloring = "lines")

    if !isnothing(color)
        # support a named colorscale or a single color
        builtin_color_scales = ("YlOrRd", "YlGnBu", "RdBu",
                                "Portland", "Picnic", "Jet", "Hot",
                                "Greys", "Greens", "Bluered",
                                "Electric", "Earth","Blackbody")
        if color ∈ builtin_color_scales
            c.colorscale=color
        else
            c.line.color = color # no effect if coloring=lines!!!
        end
    end
    !isnothing(linewidth) && (c.line.width = linewidth)
    !isnothing(colorbar) && (c.showscale = colorbar)

    if !isnothing(levels) # something with a step or single number
        c.autocontour = false
        if hasmethod(step, (typeof(levels),))
            l,r = extrema(levels)
            s = step(levels)
        else
            l = r = first(levels)
            s = 0
        end
        c.contours.start = l
        c.contours.size  = s
        c.contours."end" = r
    end

    ## labels (adjust font? via contours.labelfont
    c.contours.showlabels = contour_labels

    push!(p.data, c)
    p
end

"""
    implicit_plot(f; xlims=(-5,5), ylims=(-5,5), legend=false, linewidth=2, kwargs...)
    implicit_plot!([p::Plot], f; kwargs...)

For `f(x,y) = ...` plot implicitly defined `y(x)` from `f(x,y(x)) = 0` over range specified by `xlims` and `ylims`.

## Example
```
f(x,y) = x * y - (x^3 + x^2 + x + 1)
implicit_plot(f)
```

(Basically just `contour` plot with `levels=0` and points detremined by extrema of `xlims` and `ylims`.)
"""
function implicit_plot(f::Function; kwargs...)
    p = _new_plot(; kwargs...)
    implicit_plot!(p, f; kwargs...)
end

implicit_plot!(f::Function; kwargs...) = implicit_plot!(current_plot[], f; kwargs...)
function implicit_plot!(p::Plot, f::Function;
                        xlims=(-5, 5), ylims=(-5, 5),
                        legend=false,
                        linewidth=2,
                        kwargs...)

    xs = range(extrema(xlims)..., length=100)
    ys = range(extrema(ylims)..., length=100)
    zs = f.(xs', ys)
    contour!(p, xs, ys, zs;
             levels=0,  colorbar=legend, linewidth,
             kwargs...)
end

##

"""
    heatmap(x, y, z; kwargs...)
    heatmap!([p::Plot], x, y, z; kwargs...)
    heatmap(x, y, f::Function; kwargs...)
    heatmap!(x, y, f::Function; kwargs...)

Create heatmap function of `f`
"""
function heatmap(x, y, z; kwargs...)
    p = _new_plot(; kwargs...)
    heatmap!(p, x, y, z; kwargs...)
end

heatmap(x, y, f::Function; kwargs...) =
    heatmap(x,y, f.(x', y); kwargs...)

heatmap!(x, y, z; kwargs...) =
    heatmap!(current_plot[], x, y, z; kwargs...)
heatmap!(x, y, f::Function; kwargs...) =
    heatmap!(current_plot[], x, y, f.(x', y); kwargs...)

function heatmap!(p::Plot, x, y, z;
                  kwargs...)

    x, y, z = _adjust_matrix.((x,y,z))
    c = Config(; x, y, z, type="heatmap")
    _merge!(c; kwargs...)

    push!(p.data, c)
    p
end

##
"""
    surface(x, y, z; kwargs...)
    surface!(x, y, z; kwargs...)
    surface(x, y, f::Function; kwargs...)
    surface!(x, y, f::Function; kwargs...)

Create surface plot. Pass `zcontour=true` to add contour plot projected onto the `z` axis.

# Example

```
f(x,y) = 4 - x^2 - y^2
xs = ys = range(-2, 2, length=50)
surface(xs, ys, f)  # zs = f.(xs', ys)
```

## Extended help

From https://discourse.julialang.org/t/3d-surfaces-time-slider/109673
```
z1 = Vector[[8.83, 8.89, 8.81, 8.87, 8.9, 8.87],
                       [8.89, 8.94, 8.85, 8.94, 8.96, 8.92],
                       [8.84, 8.9, 8.82, 8.92, 8.93, 8.91],
                       [8.79, 8.85, 8.79, 8.9, 8.94, 8.92],
                       [8.79, 8.88, 8.81, 8.9, 8.95, 8.92],
                       [8.8, 8.82, 8.78, 8.91, 8.94, 8.92],
                       [8.75, 8.78, 8.77, 8.91, 8.95, 8.92],
                       [8.8, 8.8, 8.77, 8.91, 8.95, 8.94],
                       [8.74, 8.81, 8.76, 8.93, 8.98, 8.99],
                       [8.89, 8.99, 8.92, 9.1, 9.13, 9.11],
                       [8.97, 8.97, 8.91, 9.09, 9.11, 9.11],
                       [9.04, 9.08, 9.05, 9.25, 9.28, 9.27],
                       [9, 9.01, 9, 9.2, 9.23, 9.2],
                       [8.99, 8.99, 8.98, 9.18, 9.2, 9.19],
                       [8.93, 8.97, 8.97, 9.18, 9.2, 9.18]]
xs , ys = 1:length(z1[1]), 1:length(z1) # needed here given interface chosen
surface(xs, ys, z1, colorscale="Viridis")
surface!(xs, ys, map(x -> x .+ 1, z1), colorscale="Viridis", showscale=false, opacity=0.9)
surface!(xs, ys, map(x -> x .- 1, z1), colorscale="Viridis", showscale=false, opacity=0.9)
```

`Julia` users would typically use a matrix to hold the `z` data, but Javascript users would expect a vector of vectors, as above. As `PlotlyLight` just passes on the data to Javascript, the above is perfectly acceptable. Indeed `PlotlyLightLite` converts matrices to this format in such plots.

(The keyword arguments above come from `Plotly`, not `Plots`.)

A parameterized surface can be displayed. Below the `unzip` function returns 3 matrices specifying the surface described by the vector-valued function `r`.

```
r1, r2 = 2, 1/2
r(u,v) = ((r1 + r2*cos(v))*cos(u), (r1 + r2*cos(v))*sin(u), r2*sin(v))
us = vs = range(0, 2pi, length=25)
xs, ys, zs = unzip(us, vs, r)

surface(xs, ys, zs)
```


Plotting a vertical plane poses a slight challenge, as we can't parameterize as `z=f(x,y)`. Here we intersect a surface with the plane `ax + by + 0z = d` and add a trace for the intersection of the two surfaces.

```
f(x, y) = 4 - (x^2 + y^2)

# surface
xs =  ys = range(-2, 2, length=100)
zs = f.(xs', ys)

# (vertical) plane
m, M = extrema(zs)
zzs = range(m, M, length=2)
Xs = ((x,z) -> x).(xs', zzs)
Zs = ((x,z) -> z).(xs', zzs)
a, b, c, d = 1, 1, 0, 1
plane(x,z) = (d - a*x - c*z) / b
Ys = plane.(xs', zzs)

# intersection
g(t) = (d - a*t) / b
γ(t) = (t, y(t), f(t, y(t)))

surface(xs, ys, zs)
surface!(Xs, Ys, Zs, opacity=0.2)
plot!(unzip(γ.(xs))...; linewidth=3)
```
"""
function surface(x, y, z; kwargs...)
    p = _new_plot(; kwargs...)
    surface!(p, x, y, z; kwargs...)
end

surface(x, y, f::Function; kwargs...) =
    surface(x, y, f.(x', y); kwargs...)

surface!(x, y, z; kwargs...) =
    surface!(current_plot[], x, y, z; kwargs...)

surface!(x, y, f::Function; kwargs...) =
    surface!(current_plot[], x, y, f.(x', y); kwargs...)

function surface!(p::Plot, x, y, z;
                  eye = nothing, # (x=1.35, y=1.35, z=..)
                  center = nothing,
                  up = nothing,
                  zcontour = false,
                  aspect_ratio=nothing,
                  kwargs...)

    x, y, z = _adjust_matrix.((x,y,z))
    c = Config(;x,y,z,type="surface")
    _merge!(c; kwargs...)

    # configuration options? colors?
    if zcontour
        c.contours.z = Config(show=true, usecolormap=true,
                              project=Config(;z=true))
    end

    # camera controls
    _camera_position!(p.layout.scene.camera; center, up, eye)

    if !isnothing(aspect_ratio)
        if aspect_ratio == :equal
            p.layout.scene.aspectmode = "data"
            p.layout.scene.aspectratio = Config(x=1, y=1, z=1)
        end
    end

    push!(p.data, c)
    p
end

"""
    wireframe(x, y, z; kwargs...)
    wireframe(x, y, f::Function; kwargs...)
    wireframe!([p::Plot], x, y, z; kwargs...)
    wireframe!([p::Plot], x, y, f::Function; kwargs...)

Create wireframe.

# Example

```
f(x, y) = 4 - x^2 - y^2
xs = ys = range(-2, 2, length=100)
surface(xs, ys, f)
wireframe!(xs, ys, f)
```
"""
function wireframe(x, y, z; kwargs...)
    p = _new_plot(; kwargs...)
    wireframe!(p, x, y, z; kwargs...)
end

wireframe(x, y, f::Function; kwargs...) =
    wireframe(x, y, f.(x', y); kwargs...)

wireframe!(x, y, z; kwargs...) =
    wireframe!(current_plot[], x, y, z; kwargs...)

wireframe!(x, y, f::Function; kwargs...) =
    wireframe!(current_plot[], x, y, f.(x', y); kwargs...)

function wireframe!(p::Plot, x, y, z; kwargs...)
    surface!(p, x, y, z; kwargs...)
    # surface plot with modifications
    d = p.data[end]
    d.hidesurface = true
    d.contours.x.show = true
    d.contours.y.show = true

    p
end


# generalize shapes (line, rect, circle, ...)
# fillcolor
# line.color
function _shape(type, x0, x1, y0, y1; line=nothing, kwargs...)
    c = Config(; type, x0, x1, y0, y1)
    _merge!(c; kwargs...)
    !isnothing(line) && (c.line = Config(line))
    c
end

function _add_shape!(p::Plot, d)
    if isempty(p.layout.shapes)
        p.layout.shapes = [d]
    else
        push!(p.layout.shapes, d)
    end
    p
end

function vline!(p::Plot, x::Real; kwargs...)
    _add_shape!(p, _shape("line", x, x, extrema(p).y...; kwargs...))
end
vline!(x::Real; kwargs...) = vline!(current_plot[], x; kwargs...)

function hline!(p::Plot, y::Real; kwargs...)
    _add_shape!(p, _shape("line", extrema(p).x..., y, y; kwargs...))
end
hline!(x::Real; kwargs...) = hline!(current_plot[], x; kwargs...)

"""
    rect!([p::Plot], x0, x1, y0, y1; kwargs...)

Draw rectangle shape.
# Example
Use named tuple for `line` for boundary.
```
rect!(p, 2,3,-1,1; line=(color=:gray,), fillcolor=:red, opacity=0.2)
```
"""
function rect!(p::Plot, x0, x1, y0, y1; kwargs...)
    _add_shape!(p, _shape("rect", x0, x1, y0, y1; kwargs...))
end
rect!(x0, x1, y0, y1; kwargs...) = rect!(current_plot[], x0, x1, y0, y1; kwargs...)

"""
    circle([p::Plot], x0, x1, y0, y1; kwargs...)

Draw circle shape bounded in `[x0, x1] × [y0,y1]`. (Will adjust to non-equal sized boundary.)
# Example
Use named tuple for `line` for boundary.
```
circle!(p, 2,3,-1,1; line=(color=:gray,), fillcolor=:red, opacity=0.2)
```
"""
function circle!(p::Plot, x0, x1, y0, y1; kwargs...)
    _add_shape!(p, _shape("circle", x0, x1, y0, y1; kwargs...))
end
circle!(x0, x1, y0, y1; kwargs...) =
    circle!(current_plot[], x0, x1, y0, y1; kwargs...)

## ----
"""
    ★(q, xs, ys, zs; kwargs...)
    ★!([p::Plot], q, xs, ys, zs; kwargs...)

A star connected region has an origin, `q`, for which each boundary point (described by `(xs, ys, zs)` is accessible by a ray for `q` which does not cross the boundary.

## Example

```
pts = 5
Δ = 2pi/pts/2
a, A = 1, 3
q = [0,0,0]
ts = range(0, 2pi, length=pts+1)
ps = [(A*[cos(t),sin(t),0], a*[cos(t+Δ), sin(t+Δ), 0]) for t in ts]
xs, ys, zs = unzip(collect(Base.Iterators.flatten(ps)))
★(q, xs, ys, zs)
```

"""
function ★(q, xs, ys, zs; kwargs...)
    p = _new_plot(; kwargs...)
    ★!(p, q, xs, ys, zs; kwargs...)
end

★!(q, xs, ys, zs; kwargs...) =
    ★!(current_plot[], xs, ys, zs; kwargs...)

function ★!(p::Plot, q, xs, ys, zs; kwargs...)
    x = copy(xs); pushfirst!(x, q[1])
    y = copy(ys); pushfirst!(y, q[2])
    z = copy(zs); pushfirst!(z, q[3])

    n = length(x)
    i = zeros(Int,n-1)
    j = 1:n-1
    k = mod.(1 .+ j, n)

    d = Config(;x,y,z,i,j,k, type="mesh3d", kwargs...)
    push!(p.data, d)
    p
end

"""
    ziptie(xs, ys, zs, xs′, ys′, zs′; kwargs...)
    ziptie!([p::Plot], xs, ys, zs, xs′, ys′, zs′; kwargs...)

surface created by connecting points along two paths given by `(xs, ys, zs)` and `(xs′, ys′, zs′)`. All vectors must be same length. Mesh is created by zipping together points on the two curves.

## Example

```
r(t) = (sin(t), cos(t), t)
s(t) = (sin(t+pi), cos(t+pi), t)
ts = range(0, 4pi, length=100)
ziptie(unzip(r.(ts))..., unzip(s.(ts))...;
       color="green", opacity=.25, showscale=false)
```
"""
function ziptie(xs, ys, zs, xs′, ys′, zs′; kwargs...)
    p = _new_plot(; kwargs...)
    ziptie!(p, xs, ys, zs, xs′, ys′, zs′; kwargs...)
end
ziptie!(xs, ys, zs, xs′, ys′, zs′; kwargs...) =
    ziptie!(current_plot[], xs, ys, zs, xs′, ys′, zs′; kwargs...)

function ziptie!(p::Plot, xs, ys, zs, xs′, ys′, zs′; kwargs...)
    # need to join xs, ys, zs to get x,y,z

    x = collect(Base.Iterators.flatten(zip(xs,xs′)))
    y = collect(Base.Iterators.flatten(zip(ys,ys′)))
    z = collect(Base.Iterators.flatten(zip(zs,zs′)))

    n = length(x)
    iₛ = 0:2:(n-4)
    i = collect(Base.Iterators.flatten(zip(iₛ, iₛ .+ 1)))
    j = i .+ 1
    k = i .+ 2
    d = Config(; x, y, z, i, j, k, type="mesh3d", kwargs...)
    push!(p.data, d)
    p
end

## ----

# a few implementations of shapes: a parallelogram; a disc; a "skirt"
"""
    parallelogram(q, v̄, w̄; kwargs...)
    parallelogram!([p::Plot], q, v̄, w̄; kwargs...)

Plot parallelogram formed by two vectors, `v̄` and `w̄`, both anchored at point `q`.
"""
function parallelogram(q, v̄, w̄; kwargs...)
    p = _new_plot(;kwargs...)
    parallelogram!(p, q, v̄, w̄; kwargs...)
end
parallelogram!(q, v̄, w̄; kwargs...) =
    parallelogram!(current_plot[], q, v̄, w̄; kwargs...)

function parallelogram!(p::Plot, q, v̄, w̄; kwargs...)
    xyzₛ = [q + v̄, q + v̄ + w̄, q + w̄]
    ★!(p, q, unzip(xyzₛ)...; kwargs...)
end

"""
    circ3d(q, r, n̄; kwargs...)
    circ3d!([p::Plot], q, r, n̄; kwargs...)

Plot circle in 3 dimensions with center at `q`, radius `r`, and perpendicular to normal vector `n̄`.

# Example
```
q, n = [0,0,0], [0,0,1]
circ3d(q, 3, n)
arrow!(q, n)
```

Or a more complicated one:

```
Z(r, θ) = 4 - r
X(r, θ) = r * cos(θ)
Y(r, θ) = r * sin(θ)
rs = range(0,4, length=10)
θs = range(0, 2pi, length=100)
surface(X.(rs', θs), Y.(rs', θs), Z.(rs', θs); opacity=0.25)
q = [0,0,2]
n = [0,0,1]
r = 2
circ3d!(q, r, n; color="black", opacity=0.75)
q, v̂, ŵ = [0,0,0], [0,4,0], [0,0,4]
parallelogram!(q, v̂, ŵ; opacity=0.5, color=:yellow)
```
"""
function circ3d(q, r, n̄; kwargs...)
    p = _new_plot(;kwargs...)
    circ3d!(p, q, r, n̄; kwargs...)
end
circ3d!(q, r, n̄; kwargs...) =
    circ3d!(current_plot[], q, r, n̄; kwargs...)

function circ3d!(p::Plot, q, r, n̄; kwargs...)
    _cross = (v,w) -> [v[2]*w[3] - v[3]*w[2], -v[1]*w[3] + v[3]*w[1], v[1]*w[2] - v[2]*w[1]]
    _norm = v -> sqrt(sum(vᵢ^2 for vᵢ∈v))

    n = 100

    v = n̄
    v̂ = v / _norm(v)

    if iszero(v[1]) && iszero(v[2])
        ŵ = [1,0,0]
    else
        w = [v[2],-v[1],0]
        ŵ = w / _norm(w)
    end

    û = _cross(v̂,  ŵ)

    xyzₛ = [q + cos(t) * (r*ŵ)+ sin(t) * (r*û) for t in range(0, 2pi, length=n)]

    ★!(p, q, unzip(xyzₛ)...; kwargs...)
end

"""
    skirt(q, v, f::Function; kwargs...)
    skirt!([p::Plot], q, v, f::Function; kwargs...)
    skirt!([p::Plot], xs, ys, zs, f::Function; kwargs...)

Along a path `(xs, ys, zs)` plot a skirt between the path and `(xs, ys, f(xs, ys))`. The case of a path described by a vector, `v`, anchored at a point `q` has a special method.

## Example
```
x(r, θ) = r*cos(θ)
y(r, θ) = r*sin(θ)
f(x,y) = 4 - x^2 - y^2
rs, θs = range(0,2,length=10), range(0, 2pi, length=20)
xs, ys = x.(rs', θs), y.(rs', θs)
zs = f.(xs, ys)
surface(xs, ys, zs, opacity=.2, showscale=false)

q = [0,0,0]
v = [2,0,0]
d = skirt!(q, v, f; opacity=0.6)

t = range(0, 1, length=100)
xs = 2 * t .* sin.(t*pi/2)
ys = 2 * t .* cos.(t*pi/2)
zs = zero.(xs)
skirt!(xs, ys, zs, f; color="blue", opacity=0.6)
skirt!(xs, -ys, zs, f; color="blue", opacity=0.6)
```

"""
function skirt(q, v, f::Function; kwargs...)
    p = _new_plot(;kwargs...)
    skirt!(p, q, v, f; kwargs...)
end
skirt!(q, v, f::Function; kwargs...) = skirt!(current(), q, v, f; kwargs...)
function skirt!(p::Plot, q, v, f::Function; kwargs...)
    ts = range(0, 1, length=100)
    xs, ys, zs = unzip([q + t*v for t ∈ ts])
    skirt!(p, xs, ys, zs, f; kwargs...)
end

# xs, ys, zs are path in space
function skirt(xs, ys, zs, f::Function; kwargs...)
    p = _new_plot()
    skirt!(p, xs, ys, zs, f)
end
skirt!(xs, ys, zs, f::Function; kwargs...) =
    skirt!(current_plot[], xs, ys, zs, f; kwargs...)

function skirt!(p::Plot, xs, ys, zs, f::Function; kwargs...)
    zs′ = f.(xs, ys)
    ziptie!(p, xs, ys, zs, xs, ys, zs′; kwargs...)
end



## ----

"""
    annotate!([p::Plot], x, y, txt; [color], [family], [pointsize], [halign], [valign])
    annotate!([p::Plot], anns::Tuple;  kwargs...)

Add annotations to plot.

* x, y, txt: text to add at (x,y)
* color: text color
* family: font family
* pointsize: text size
* halign: one of "top", "bottom"
* valign: one of "left", "right"
* rotation: angle to rotate

The `x`, `y`, `txt` values can be specified as 3 iterables or tuple of tuples.
"""
function annotate!(p::Plot, x, y, txt;
                   color= nothing,
                   family = nothing,
                   pointsize = nothing,
                   halign = nothing,
                   valign = nothing,
                   rotation = nothing,
                   kwargs...)

    cfg = Config(; x, y, text=txt, mode="text", type="scatter")

    textposition = _something(strip(join(something.((halign, valign), ""), " ")))
    #_merge!(cfg; textposition)
    _textstyle!(cfg; color, family, pointsize, rotation, textposition, kwargs...)

    push!(p.data, cfg)
    p
end

annotate!(p::Plot, anns::Tuple; kwargs...) = annotate!(p, unzip(anns)...; kwargs...)
annotate!(p::Plot, anns::Vector; kwargs...) = annotate!(p, unzip(anns)...; kwargs...)
annotate!(x, y, txt; kwargs...) = annotate!(current_plot[], x, y, txt; kwargs...)
annotate!(anns::Tuple; kwargs...) = annotate!(current_plot[], anns; kwargs...)
annotate!(anns::Vector; kwargs...) = annotate!(current_plot[], anns; kwargs...)

# arrow from u to u + du with optional text at tail
function _arrow(u,du,txt=nothing;
                arrowhead=nothing,
                arrowwidth=nothing,
                arrowcolor=nothing,
                showarrow=nothing,
                kwargs...)
    cfg = Config()
    ax, ay = u
    x, y = u .+ du
    xref = axref = "x"
    yref = ayref = "y"
    _merge!(cfg; x, y, ax, ay,
            text=txt,
            xref,yref, axref, ayref,
            arrowhead, arrowwidth, arrowcolor, showarrow,
            kwargs...)
    cfg
end

"""
    quiver!([p::Plot], x, y, txt=nothing; quiver=(dx, dy), kwargs...)
    quiver(x, y, txt=nothing; quiver=(dx, dy), kwargs...)

Draw 2d arrows. See `arrow!` for a single arrow.

* `(x,y)` are tail positions, optionally labeled by `txt`
* `quiver` specifies vector part of arrow
* `kwargs process `arrowhead::Int?`, `arrowwidth::Int?`, `arrowcolor`

# Example

```julia
ts = range(0, 2pi, length=100)
p = plot(sin.(ts), cos.(ts), linecolor="red")
ts = range(0, 2pi, length=10)
quiver!(p, cos.(ts), sin.(ts), quiver=(-sin.(ts), cos.(ts)), arrowcolor="red")
p
```

This example shows how text can be rotated with angles in degrees and positive angles measured in a *clockwise* direction.

```
ts = range(0, 2pi, 100)
p = plot(cos.(ts), sin.(ts), linecolor="red", aspect_ratio=:equal,
    linewidth=20, opacity=0.2)

txt = split("The quick brown fox jumped over the lazy dog")
ts = range(0, 360, length(txt)+1)[2:end]
for (i,t) ∈ enumerate(reverse(ts))
    quiver!(p, [cosd(t)],[sind(t)],txt[i],
            quiver=([0],[0]),
            textangle=90-t,
            font=(size=20,))
end
xaxis!(zeroline=false); yaxis!(zeroline=false) # remove zerolines
p
```

!!! note "3d arrows"
    3d arrows are possible using `arrows!`.

"""
function quiver!(p::Plot, x, y, txt=nothing; quiver=nothing, kwargs...)
    us = zip(x,y)
    dus = zip(quiver...)
    as = _arrow.(us, dus, txt; kwargs...)
    if isempty(p.layout.annotations)
        p.layout.annotations = Config[]
    end
    append!(p.layout.annotations, as)
    p
end
quiver!(x, y, txt=nothing; quiver=nothing, kwargs...) =
    quiver!(current_plot[], x, y, txt; quiver=quiver, kwargs...)

function quiver(as...; kwargs...)
    p = _new_plot(; kwargs...)
    quiver!(p, as...; kwargs...)
end

# quiver works on vectors x,y,z,u,v,w
# arrow works on vectors of (x,y,z), (u,v,w) points
# quiver only 2d
# work in tail, Δ form
"""
    arrow(tails, vs; kwargs...)

Draw vectors `vs` anchored at `tails`.
Hacked in support for 3D using combination of lines + cones.

Use `Plotly` attributes `arrowcolor`, `arrowwidth`,
"""
function arrow(tails, vs; kwargs...)
    p = _new_plot(; kwargs...)
    arrow!(p, tails, vs; kwargs...)
    p
end

arrow!(tails, vs; kwargs...) = arrow!(current_plot[], tails, vs; kwargs...)

function arrow!(p::Plot, tails, vs; kwargs...)
    # what kind of data two points or
    # vectors of points
    _tail = first(tails)
    if isa(_tail, Number)
        N = length(tails)
        tails = [tails]
        vs = [vs]
    else
        __tail = first(_tail)
        !isa(__tail, Number) && throw(ArgumentError("Not a point or container of points"))
        N = length(_tail)
    end
    arrow!(p, Val(N), tails, vs; kwargs...)
end

function arrow!(p::Plot, ::Val{2}, tails, vs; kwargs...)
    quiver!(p, unzip(tails)..., quiver=tuple(unzip(vs)...); kwargs...)
    p
end


# λ may change!
# too fiddly
function arrow!(p::Plot, ::Val{3}, tails, vs; λ = 0.1, showscale=false, kwargs...)
    _norm(x) = sqrt(sum(xᵢ*xᵢ for xᵢ ∈ x))

    tips = map(.+, tails, vs)
    x0,y0,z0 = unzip(tails)
    x1,y1,z1 = unzip(tips)
    #pad with NaN
    x = collect(Iterators.flatten([[a,b,nothing] for (a,b) ∈ zip(x0,x1)]))
    y = collect(Iterators.flatten([[a,b,nothing] for (a,b) ∈ zip(y0,y1)]))
    z = collect(Iterators.flatten([[a,b,nothing] for (a,b) ∈ zip(z0,z1)]))

    d1 = Config(;x,y,z, type="scatter3d", mode="lines", showscale, kwargs...)
    push!(p.data, d1)

    x,y,z = unzip(tips)
    du,dv,dw = unzip(vs)

    # adjust length of cone. This is fiddly
    # https://plotly.com/python-api-reference/generated/plotly.graph_objects.Cone.html


    # not sure this is better than unit vectors...
    M = maximum(_norm.(vs))
    u, v, w = du ./ M, dv ./ M, dw ./ M
    #u,v,w = du, dv, dw
    λ *= log10(10 + length(x))

    d2 = Config(;type="cone",
                x,y,z,
                u,v,w,
                anchor="tip",
                sizemode="absolute",
                sizeref=  λ*M,
                showscale,
                kwargs...)
    push!(p.data,  d2)
    p
end




"""
    title!([p::Plot], txt)
    xlabel!([p::Plot], txt)
    ylable!([p::Plot], txt)
    zlabel!([p::Plot], txt)

Set plot title.
"""
function title!(p::Plot, txt)
    p.layout.title = txt
    p
end
title!(txt) = title!(current_plot[], txt)

xlabel!(p::Plot, txt) = (p.layout.xaxis.title=txt;p)
xlabel!(txt) = xlabel!(current_plot[], txt)

ylabel!(p::Plot, txt) = (p.layout.yaxis.title=txt;p)
ylabel!(txt) = ylabel!(current_plot[], txt)

zlabel!(p::Plot, txt) = (p.layout.zaxis.title=txt;p)
zlabel!(txt) = zlabel!(current_plot[], txt)

"""
    xaxis!([p::Plot]; kwargs...)
    yaxis!([p::Plot]; kwargs...)
    zaxis!([p::Plot]; kwargs...)

Adjust ticks on chart.
* ticks: a container or range
* ticklabels: optional labels (same length as `ticks`)
* showticklabels::Bool
"""
xaxis!(p::Plot; kwargs...) = (_merge!(p.layout.xaxis, _axis(;kwargs...)); p)
xaxis!(;kwargs...) = xaxis!(current_plot[]; kwargs...)
yaxis!(p::Plot; kwargs...) = (_merge!(p.layout.yaxis, _axis(;kwargs...)); p)
yaxis!(;kwargs...) = yaxis!(current_plot[]; kwargs...)
zaxis!(p::Plot; kwargs...) = (_merge!(p.layout.zaxis, _axis(;kwargs...)); p)
zaxis!(;kwargs...) = zaxis!(current_plot[]; kwargs...)
# https://plotly.com/javascript/tick-formatting/ .. more to do
function _axis(;ticks=nothing, ticktext=nothing, showticklabels=nothing,
               autotick=nothing, showgrid=nothing, zeroline=nothing,
               kwargs...
                )
    d = Config()
    if !isnothing(ticks)
        if isa(ticks, AbstractRange)
            tickvals, tick0, dtick, nticks = nothing, first(ticks), step(ticks), length(ticks)
        else
            tickvals, tick0, dtick, nticks = ticks, nothing, nothing, nothing
        end
        _merge!(d; tickvals, tick0, dtick, nticks)
    end
    _merge!(d; ticktext, showticklabels, autotick, showgrid, zeroline)
    d
end

"`legend!([p::Plot], legend::Bool)` hide/show legend"
legend!(p::Plot, legend=nothing) = !isnothing(legend) && (p.layout.showlegend = legend)
legend!(val::Bool) = legend!(current_plot[], val)

"`size!([p::Plot]; [width], [height])` specify size of plot figure"
function size!(p::Plot; width=nothing, height=nothing)
    !isnothing(width) && (p.layout.width=width)
    !isnothing(height) && (p.layout.height=height)
    p
end
size!(;width=nothing, height=nothing) = size!(current_plot[]; width, height)

"`xlims!(p, lims)` set `x` limits of plot"
function xlims!(p::Plot, lims)
    p.layout.xaxis.range = lims
    p
end
xlims!(p::Plot, ::Nothing) = p
xlims!(lims) = xlims!(current_plot[], lims)

"`ylims!(p, lims)` set `y` limits of plot"
function ylims!(p::Plot, lims)
    p.layout.yaxis.range = lims
    p
end
ylims!(p::Plot, ::Nothing) = p
ylims!(lims) = ylims!(current_plot[], lims)

"`zlims!(p, lims)` set `z` limits of plot"
function zlims!(p::Plot, lims)
    p.layout.xaxis.range = lims
    p
end
zlims!(p::Plot, ::Nothing) = p
zlims!(lims) = zlims!(current_plot[], lims)

"`scrollzoom!([p], x::Bool)` turn on/off scrolling to zoom"
scroll_zoom!(p::Plot,x::Bool) = p.config.scrollZoom = x
scroll_zoom!(x::Bool) = scroll_zoom!(current_plot[], x)

## ---- configuration
# These gather specific values for lines, marker and text style

# linecolor - color
# linewidth - integer
# linestyle: solic, dot, dashdot, ...
# lineshape: linear, hv, vh, hvh, vhv, spline
function _linestyle!(cfg::Config;
                     linecolor = nothing, # string, symbol, RGB?
                     linewidth = nothing, # pixels
                     linestyle = nothing, # solid, dot, dashdot,
                     lineshape = nothing,
                     kwargs...)
    _merge!(cfg.line; color=linecolor, width=linewidth, dash=linestyle,
            shape=lineshape)
    _merge!(cfg; kwargs...)
end


function _markerstyle!(cfg::Config;
                       markershape = nothing,
                       markersize  = nothing,
                       markercolor = nothing,
                       kwargs...)
    _merge!(cfg.marker; symbol=markershape, size=markersize, color=markercolor)
    _merge!(cfg; kwargs...)
end

function _textstyle!(cfg::Config;
                     color     = nothing,
                     family    = nothing,
                     pointsize = nothing,
                     rotation  = nothing,
                     kwargs...)
    _merge!(cfg.textfont, color=color, family=family, size=pointsize,
            textangle=rotation)
    _merge!(cfg; kwargs...)
end

# The camera position and direction is determined by three vectors: up, center, eye.
#
# Their coordinates refer to the 3-d domain, i.e., (0, 0, 0) is always the center of the domain, no matter data values.
#
# The eye vector determines the position of the camera. The default is $(x=1.25, y=1.25, z=1.25)$.
#
# The up vector determines the up direction on the page. The default is $(x=0, y=0, z=1)$, that is, the z-axis points up.
#
#  The projection of the center point lies at the center of the view. By default it is $(x=0, y=0, z=0)$. [https://plotly.com/python/3d-camera-controls/]
#
function _camera_position!(camera::Config;
                          center,
                          up,
                          eye)
    _merge!(camera; center)
    _merge!(camera; up)
    _merge!(camera; eye)
end

## -----
"""
    grid_layout(ps::Array{<:Plot})

Layout an array of plots into a grid. Vectors become rows of plots.

Use `Plot()` to create an empty plot for a given cell.

# Example

```
using DataFrames
n = 25
d = DataFrame(x=sin.(rand(n)), y=rand(n).^2, z = rand(n)) # assume all numeric
nms = names(d)
m = Matrix{Plot}(undef, length(nms), length(nms))

for i ∈ eachindex(nms)
    for j ∈ eachindex(nms)
        if j > i
            p = Plot()
        elseif j == i
            x = d[:,j]
            p = plot(x, type="histogram")
            xlabel!(p, nms[j])  # <<- not working in grid! as differe xaxis purposes
        else
            x = d[:,i]; y = d[:,j]
            p = scatter(x, y)
            xlabel!(p, nms[i]); ylabel!(p, nms[j])
        end
        m[i,j] = p
    end
end
grid_layout(m)
```
"""
function grid_layout(ps::Array{<:Plot};
                     pattern="independent", # or "coupled"
                     legend = false,
                     )
    mn = size(ps)
    if length(mn) == 1
        m, n = (1, only(mn))
    else
        m, n = mn
    end

    layout = Config()
    layout.grid.rows = m
    layout.grid.columns = n
    !isnothing(pattern) && (layout.grid.pattern = pattern)
    !isnothing(legend) && (layout.showlegend = legend)

    data = Config[]
    for (i,p) ∈ enumerate(permutedims(ps))
        xi,yi = "x$i", "y$i"
        for d ∈ p.data
            isempty(d) && continue
            d.xaxis = xi
            d.yaxis = yi
            push!(data, d)
        end
    end

    Plot(data, layout)
end
