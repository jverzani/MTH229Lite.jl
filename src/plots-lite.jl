## --- plotting

## create a simplish 2D Plots.plot like interface for PlotlyLight.Plot

## utils
const current_plot = Ref{Plot}() # store current plot
const first_plot = Ref{Bool}(true) # for first plot warning

# make a new plot by calling `PlotlyLight.Plot`
function _new_plot(;
                   width=800, height=600,
                   xlims=nothing, ylims=nothing,
                   legend = nothing,
                   kwargs...)
    p = Plot(Config[], # data
             Config(), # layout
             Config(responsive=true, scrollZoom=true) ) # config
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


    p
end

function _merge!(c::Config; kwargs...)
    for kv ∈ kwargs
        k,v = kv
        v = isa(v,Pair) ? last(v) : v
        isnothing(v) && continue
        c[k] = v
    end
end

function _join!(xs, delim="")
    xs′ = filter(!isnothing, xs)
    isempty(xs′) && return nothing
    join(string.(xs′), delim)
end


## ----

"""
    plot(x, y, [z]; [linecolor], [linewidth], [legend], kwargs...)
    plot(f::Function, a, b; kwargs...)

Create a line plot.

Returns a `Plot` instance from [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl)

* x,y points to plot. NaN values in `y` break the line
* linecolor: color of line
* linewidth: width of line
* label

Other keyword arguments include `width` and `height`, `xlims` and `ylims`, `legend`.

Provides an interface like `Plots.plot` for plotting a function `f` using `PlotlyLight`. This just scratches the surface, but `PlotlyLight` allows full access to the underlying `JavaScript` [library](https://plotly.com/javascript/) library.

The provided "`Plots`-like" functions are [`plot`](@ref), [`plot!`](@ref), [`scatter!`](@ref), `scatter`, [`annotate!`](@ref),  [`title!`](@ref), [`xlims!`](@ref) and [`ylims!`](@ref).

# Example

```
plot(sin, 0, 2pi; legend=false)
plot!(cos)
x0 = [pi/4, 5pi/4]
scatter!(x0, sin.(x0), markersize=10)
annotate!(tuple(zip(x0, sin.(x0), ("A", "B"))...), halign="left", pointsize=12)
title!("Sine and cosine and where they intersect in [0,2π]")
ylims!((-3/2, 3/2))
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

plot(f::Function, I::Interval; kwargs...) = plot(f, I...; kwargs...)

"""
    plot!([p::Plot], x, y; kwargs...)
    plot!([p::Plot], f; kwargs...)

Used to add a new tract to an existing plot. Like `Plots.plot!`
"""
function plot!(p::Plot, x, y;
               label = nothing,
               kwargs...)
    # fussiness to handle NaNs in `y` values
    x, y = float(x), float(y)

    y[isinf.(y)] .= NaN
    nans = findall(isnan, y)

    if !isempty(nans)
        l = 1
        push!(nans, length(y)+1)
        for r ∈ nans
            idx = l:(r-1)
            l = r + 1
            length(idx) <= 0 && continue
            _push_line_trace!(p, x[idx], y[idx]; label, kwargs...)
        end
    else
        _push_line_trace!(p, x, y; label, kwargs...)
    end

    p
end

function _push_line_trace!(p, x, y;
                           mode="lines",
                           label = nothing, kwargs...
                           )
    c = Config(; x, y, mode=mode)
    _linestyle!(c.line, kwargs...)
    _merge!(c; name=label)
    push!(p.data, c)
end

function plot!(p::Plot, x, y, z;
               label = nothing,
               kwargs...)
    # XXX handle NaNs...
    c = Config(;x,y,z,type="scatter3d", mode="lines")
    _linestyle!(c.line, kwargs...)
    _merge!(c; name=label)
    push!(p.data, c)
    p
end

function plot!(p::Plot, f::Function, a, b; kwargs...)
    x, y = unzip(f, a, b)
    plot!(p, x, y; kwargs...)
end

plot!(p::Plot, f::Function, I::Interval; kwargs...) = plot!(f, I...; kwargs...)

function plot!(p::Plot, f::Function; kwargs...)
    m,M = (Inf, -Inf)
    for d ∈ p.data
        haskey(d, :x) || continue
        a,b = extrema(d.x)
        m = min(a, m); M = max(b,M)
    end
    m < M || throw(ArgumentError("Can't identify interval to plot over"))
    plot!(p, f, m, M; kwargs...)
end

plot!(x, y; kwargs...) =  plot!(current_plot[], x, y; kwargs...)
plot!(f::Function, args...; kwargs...) =  plot!(current_plot[], f, args...; kwargs...)

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
    _markerstyle!(cfg.marker; kwargs...)

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
    _markerstyle!(cfg.marker; kwargs...)

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

function contour(x, y, f::Function; kwargs...)
    p = _new_plot(; kwargs...)
    contour!(p, x,y, f.(x', y); kwargs...)
end

function contour!(p::Plot, x, y, z;
                  colorscale = nothing,
                  contours = nothing,
                  kwargs...)
    c = Config(;x,y,z,type="contour")
    !isnothing(colorscale) && (c.colorscale=colorscale)
    if !isnothing(contours) # something with a step
        l,r = extrema(contours); s = step(contours)
        c.contours.start = l
        c.controus.size  = s
        c.contours."end" = r
    end

    push!(p.data, c)
    p
end

function surface(x, y, f::Function; kwargs...)
    p = _new_plot(; kwargs...)
    surface!(p, x, y, f.(x', y); kwargs...)
end

function surface(x, y, z; kwargs...)
    p = _new_plot(; kwargs...)
    surface!(p, x, y, z; kwargs...)
end


function surface!(p::Plot, x, y, z;
                  eye = nothing, # (x=1.35, y=1.35, z=..)
                  center = nothing,
                  up = nothing,
                  kwargs...)
    c = Config(;x,y,z,type="surface")
    # configuration options? colors?

    # camera controls
    _camera_position!(p.layout.scene.camera; center, up, eye)

    push!(p.data, c)
    p
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

The `x`, `y`, `txt` values can be specified as 3 iterables or tuple of tuples.
"""
function annotate!(p::Plot, x, y, txt;
                   color= nothing,
                   family = nothing,
                   pointsize = nothing,
                   halign = nothing,
                   valign = nothing,
                   kwargs...)

    cfg = Config(; x, y, text=txt, mode="text", type="scatter")

    textposition = join((halign, valign), " ")
    _merge!(cfg; textposition)
    _textstyle!(cfg.textfont; color, family, pointsize, kwargs...)

    push!(p.data, cfg)
    p
end

annotate!(p::Plot, anns::Tuple; kwargs...) = annotate!(p, unzip(anns)...; kwargs...)
annotate!(x, y, txt; kwargs...) = annotate!(current_plot[], x, y, txt; kwargs...)
annotate!(anns::Tuple; kwargs...) = annotate!(current_plot[], anns; kwargs...)

"""
    title!([p::Plot], txt)

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


## ---- configuration

function _linestyle!(line::Config,
                     linecolor=nothing, # string, symbol, RGB?
                     linewidth=nothing, # pixels
                     linestyle=nothing, # solid, dot, dashdot,
                     kwargs...)
    _merge!(line; color=linecolor, width=linewidth, dash=linestyle)
end


function _markerstyle!(marker::Config;
                       markershape = nothing,
                       markersize = nothing,
                       markercolor = nothing,
                       kwargs...)
    _merge!(marker; symbol=markershape, size=markersize, color=markercolor)
end

function _textstyle!(textfont::Config;
                     color=nothing,
                     family=nothing,
                     pointsize=nothing,
                     kwargs...)
    _merge!(textfont, color=color, family=family, size=pointsize)
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
    plotif(f, g, a, b)

Plot `f` colored depending on `g > 0` or `g < 0`.
"""
function plotif(f,g, a, b; width=800, height=600,
                kwargs...)
    xs = collect(range(a, b, length=251))
    cs = identify_colors(g, xs)
    cols, l = rle(cs)
    xs′ = cumsum(l); pushfirst!(xs′, 1)
    p = Plot(Config(), Config(), Config(); kwargs...)
    p.layout.showlegend = false
    size!(p; width=width, height=height)
    for i ∈ eachindex(cols)
	us = xs[xs′[i]:xs′[i+1]]
	push!(p.data, Config(x=us, y=f.(us), line=Config(color=cols[i])))
	end
    p
end

"""
    grid_layout(ps::Array{<:Plot})

Layout an array of plots into a grid. Vectors become rows of plots.

Use `Plot()` to create an empty plot for a given cell.
"""
function grid_layout(ps::Array{<:Plot};
                     pattern="independent", # or "coupled"
                     legend = false,
                     )
    mn = size(ps)
    m, n = length(mn) == 1 ? (1, only(mn)) : mn

    layout = Config()
    layout.grid.rows = m
    layout.grid.columns = n
    !isnothing(pattern) && (layout.grid.pattern = pattern)
    !isnothing(legend) && (layout.showlegend = legend)

    data = Config[]
    for (i,p) ∈ enumerate(ps)
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


## -----
## Special case for plotting SymbolicEquations
"""
    plot(eqn::SymbolicEquation, a::Real, b::Real; kwargs...)
    plot(eqn::SymbolicEquation, ab::Interval; kwargs...)

Plot equation by plotting both left-hand side and right-hand side over the specified interval. Argument `linecolor` and `linewidth` may specify two distinct values.

# Example
```julia
# cf. https://www.chebfun.org/examples/roots/Tiger.html
@symbolic x
u = 2*exp(x/2) * (sin(5*x) + sin(101*x))
v = u - round(u)
ab = -2..1
p = plot(u ~ 0, ab; linecolor=("orange","blue"), linewidth=(nothing, 2), legend=false)
xs = solve(v ~ 0, ab)
filter!(x -> abs(v(x)) <= 1/8, xs) # no jumps, 345 left
scatter!(xs, u.(xs); markercolor="black")
```
"""
function plot(ex::SimpleExpressions.SymbolicEquation, a::Real, b::Real; kwargs...)
    p = _new_plot(; kwargs...)
    plot!(p, ex, a, b; kwargs...)

end

plot(f::SimpleExpressions.SymbolicEquation, I::Interval; kwargs...) = plot(f, I.a, I.b; kwargs...)


function plot!(p::Plot, ex::SimpleExpressions.SymbolicEquation, a::Real, b::Real; linecolor=nothing, linewidth=nothing, kwargs...)
    lhs, rhs = ex.lhs, ex.rhs
    fl = SimpleExpressions.issymbolic(lhs) ? lhs : ((x) -> lhs)
    fr = SimpleExpressions.issymbolic(rhs) ? rhs : ((x) -> rhs)

    lcₗ, lcᵣ = (isa(linecolor, Vector) || isa(linecolor, Tuple)) ?
        (first(linecolor), last(linecolor)) :
         (linecolor, linecolor)

    lwₗ, lwᵣ = isnothing(linewidth) ?
        (nothing, nothing) :
        (first(linewidth), last(linewidth))


    plot!(p, fl, a, b; linecolor=lcₗ, linewidth=lwₗ, kwargs...)
    plot!(p, fr, a, b; linecolor=lcᵣ, linewidth=lwᵣ, kwargs...)
    p
end
