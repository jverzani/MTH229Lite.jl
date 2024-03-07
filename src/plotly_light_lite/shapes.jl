
# generalize shapes (line, rect, circle, ...)
# fillcolor
# line.color
function _shape(type, x0, x1, y0, y1;
                kwargs...)



    c = Config(; type, x0, x1, y0, y1)
    kws = _linestyle!(c.line; kwargs...)
    kws = _fillstyle!(c; kws...)
    _merge!(c; kws...)
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

function _add_shapes!(p::Plot, ps; kwargs...)
    if isa(ps, Config)
        _add_shape!(p, ps)
    else
        for s ∈ ps
            _add_shape!(p, s)
        end
    end
end


"""
    vline!(x; ymin=0, ymax=1.0; kwargs...)

Draw vertical line at `x`. By default extends over the current plot range, this can be adjusted by `ymin` and `ymax`, values in `[0,1]`.

The values for `x`, `ymin`, and `ymax` are broadcast.

A current plot must be made to add to, as the extent of the lines is taken from that.

# Example

Add a grid to a plot:

```
p = plot(x -> x^2, 0, 1; aspect_ratio=:equal)
vline!(0:.1:1, linecolor=:red,  opacity=0.25, linewidth=5)
hline!(0:.1:1, linecolor=:blue, opacity=0.75)
```

"""
vline!(x; kwargs...) = vline!(current_plot[], x; kwargs...)
function vline!(p::Plot, x; ymin = 0.0, ymax = 1.0, kwargs...)
    a, b = extrema(p).y
    Δ = b - a
    λ = (x,m,M) -> _shape("line", x, x, a + m*Δ, a + M*Δ; mode="Line", kwargs...)
    ps = λ.(x, ymin, ymax)

    _add_shapes!(p, ps)

    p
end

"""
    hline!(y; xmin=0, xmax=1.0; kwargs...)

Draw horizontal line at `y`. By default extends over the current plot range, this can be adjusted by `xmin` and `xmax`, values in `[0,1]`.

The values for `y`, `xmin`, and `xmax` are broadcast.

A current plot must be made to add to, as the extent of the lines is taken from that.
"""
hline!(x; kwargs...) = hline!(current_plot[], x; kwargs...)
function hline!(p::Plot, y; xmin = 0.0, xmax = 1.0, kwargs...)
    a, b = extrema(p).x
    Δ = b - a
    λ = (y,m,M) -> _shape("line", a + m*Δ, a + M*Δ, y, y; mode="line",kwargs...)
    ps = λ.(y,xmin, xmax)

    _add_shapes!(p, ps)
    p
end

"""
    ablines!([p::Plot], intercept, slope; kwargs...)

Draw line `y = a + bx` over current viewing window, as determined by
`extrema(p)`.
"""
ablines!(intercept, slope; kwargs...) = ablines!(current_plot[], intercept, slope; kwargs...)
function ablines!(p::Plot, intercept, slope;
                  kwargs...)
    xa, xb = extrema(p).x
    ya, yb = extrema(p).y

    _line = (a, b) -> begin
        if iszero(b)
            return  _shape("line", xa, xb, a, a;
                         mode = "line", kwargs...)
        end
        # line is a + bx in region [xa, xb] × [ya, yb]
        l = x -> a + b * x
        x0 = l(xa) >= ya ? xa : (ya - a)/b
        x1 = l(xb) <= yb ? xb : (yb - a)/b
        y0, y1 = extrema((l(x0), l(x1)))
        return _shape("line", x0, x1, y0, y1;
                      mode="line", kwargs...)

    end

    _add_shapes!(p, _line.(intercept, slope))
    p
end



"""
    rect!([p::Plot], x0, x1, y0, y1; kwargs...)

Draw rectangle shape on graphic.

# Example

```
rect!(p, 2,3,-1,1; linecolor=:gray, fillcolor=:red, opacity=0.2)
```
"""
function rect!(p::Plot, x0, x1, y0, y1; kwargs...)
    _add_shape!(p, _shape("rect", x0, x1, y0, y1; kwargs...))
end
rect!(x0, x1, y0, y1; kwargs...) = rect!(current_plot[], x0, x1, y0, y1; kwargs...)


"""
    hspan!([p::Plot], ys, YS; xmin=0.0, ymin=1.0, kwargs...)

Draw horizontal rectanglular rectangle from `ys` to `YS`. By default extends over `x` range of plot `p`, though using `xmin` or `xmax` can adjust that. These are values in `[0,1]` and are interpreted relative to the range returned by `extrema(p).x`.
"""
hspan!(ys,YS; kwargs...) = hspan!(current_plot[], ys, YS; kwargs...)
function hspan!(p::Plot, ys, YS; xmin=0.0, xmax=1.0, kwargs...)
    a, b = extrema(p).x
    Δ = b - a
    λ = (m,M,y0,y1) -> _shape("rect", a + m*Δ, a + M*Δ, y0, y1; kwargs...)
    ps = λ.(xmin, xmax, ys, YS)

    _add_shapes!(p, ps)

    p
end

"""
    vspan!([p::Plot], xs, XS; ymin=0.0, ymin=1.0, kwargs...)

Draw vertical rectanglular rectangle from `xs` to `XS`. By default extends over `y` range of plot `p`, though using `ymin` or `ymax` can adjust that. These are values in `[0,1]` and are interpreted relative to the range returned by `extrema(p).y`.

# Example

```
p = plot(x -> x^2, 0, 1; legend=false)
M = 1 # max of function on `[a,b]`
vspan!(0:.1:0.9, 0.1:0.1:1.0; ymax=[x^2 for x in 0:.1:0.9]/M,
    fillcolor=:red, opacity=.25)
```
"""
vspan!(xs, XS; kwargs...) = vspan!(current_plot[], xs, XS; kwargs...)
function vspan!(p::Plot, xs, XS; ymin=0.0, ymax=1.0, kwargs...)
    a, b = extrema(p).y
    Δ = b - a
    λ = (x0,x1,m,M) -> _shape("rect", x0,x1,a + m*Δ, a + M*Δ; kwargs...)
    ps = λ.(xs, XS, ymin, ymax)

    _add_shapes!(p, ps)

    p
end

# XXX poly (?https://docs.makie.org/stable/reference/plots/poly/)
"""
    poly(points; kwargs...)
    poly!([p::Plot], points; kwargs...)

Plot polygon described by `points`, a container of `x-y` or `x-y-z` values.

Example

```
f(r,θ) = (r*cos(θ), r*sin(θ))
poly(f.(repeat([1,2],5), range(0, 2pi-pi/5, length=10)))
```
"""
function poly(points; kwargs...)
    p = _new_plot(; kwargs...)
    poly!(p, points; kwargs...)
end
poly!(points; kwargs...) = poly!(current_plot[], points; kwargs...)
function poly!(p::Plot,points;
               color = nothing,
               kwargs...)
    x,y = unzip(points)
    if (first(x) != last(x)) || (first(y) != last(y))
        x, y = collect(x), collect(y)
        push!(x, first(x))
        push!(y, first(y))
    end
    cfg = Config(;x,y,type="line", color=color, fill="toself")
    kws = _linestyle!(cfg.line; kwargs...)
    kws = _fillstyle!(cfg; kws...)
    _merge!(cfg; kws...)
    push!(p.data, cfg)
    p
end



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


"""
    band(lower, upper; kwargs...)
    band(lower::Function, upper::Function, a::Real, b::Real,n=251; kwargs...)
    band!([p::Plot],lower, upper; kwargs...)
    band!([p::Plot],lower::Function, upper::Function, a::Real, b::Real,n=251; kwargs...)

Draw band between `lower` and `upper`. These may be specified by functions or by tuples of `x-y-[z]` values.

# Example

Using `(x,y)` points to define the boundaries
```
xs = 1:0.2:10
ys_low = -0.2 .* sin.(xs) .- 0.25
ys_high = 0.2 .* sin.(xs) .+ 0.25

p = plot(;xlims=(0,10), ylims=(-1.5, .5), legend=false)
band!(zip(xs, ys_low), zip(xs, ys_high); fillcolor=:blue)
band!(zip(xs, ys_low .- 1), zip(xs, ys_high .- 1); fillcolor=:red)
```

Or, using functions to define the boundaries

```
band(x -> -0.2 * sin(x) - 0.25, x -> 0.2 * sin(x) + 0.25,
     0, 10;  # a, b, n=251
     fillcolor=:red, legend=false)
```
"""
function band(lower, upper, args...; kwargs...)
    p = _new_plot(; kwargs...)
    band!(p, lower, upper, args...; kwargs...)
end
band!(lower::Function, upper::Function, a,b,n=251; kwargs...) =
    band!(current_plot[], lower, upper, a,b,n; kwargs...)
band!(lower, upper; kwargs...) =
    band!(current_plot[], lower, upper; kwargs...)

function band!(p::Plot, lower::Function, upper::Function, a::Real, b::Real, n=251; kwargs...)
    ts = range(a, b, length=n)
    ls = lower.(ts)
    us = upper.(ts)
    n = length(first(ls))
    n == 1 && return band!(p, Val(2), zip(ts, ls), zip(ts, us); kwargs...)
    band!(p, Val(n), ls, us; kwargs...)
end

function band!(p::Plot, lower, upper; kwargs...)
    n = length(first(lower))
    band!(p, Val(n), lower, upper; kwargs...)
end

# method for 2d band
function band!(p::Plot, ::Val{2}, lower, upper;
               kwargs...)

    x,y = unzip(lower)
    l1 = Config(;x,y)
    _linestyle!(l1.line; kwargs...)

    x,y = unzip(upper)
    fill = "tonexty"
    l2 = Config(;x, y, fill)
    kws = _linestyle!(l2.line; kwargs...)
    kws = _fillstyle!(l2; kws...)
    _merge!(l2; kws...)

    append!(p.data, (l1, l2))
    p
end


# image
"""
    image!([p::Plot], img_url; [x],[y],[sizex],[sizey], kwargs...)

Plot image, by url, onto background of plot.

* `x`,`y`,`sizex`, `sizey` specify extent via `[x, x+sizex] × [y-sizey, y]`.
* pass `sizing="stretch"` to fill space.
* other arguments cf. [plotly examples](https://plotly.com/javascript/images/).

# Example
```
img = "https://upload.wikimedia.org/wikipedia/commons/thumb/1/1f/Julia_Programming_Language_Logo.svg/320px-Julia_Programming_Language_Logo.svg.png"
plot(;xlims=(0,1), ylims=(0,1), legend=false);
image!(img; sizing="stretch")
plot!(x -> x^2; linewidth=10, linecolor=:black)
```
"""
image!(img; kwargs...) = image!(current_plot[], img; kwargs...)
function image!(p::Plot, img;
                x=nothing,
                y=nothing,
                sizex = nothing,
                sizey = nothing,
                kwargs...)
    isempty(p.layout.images) && (p.layout.images = Config[])

    ex = extrema(p)
    x0,x1 = ex.x
    y0,y1 = ex.y
    x = isnothing(x) ? x0 : x
    y = isnothing(y) ? y1 : y
    sizex = isnothing(sizex) ? x1 - x : sizex
    sizey = isnothing(sizey) ? y - y0 : sizey
    image = Config(;source=img, x, y, sizex, sizey,
                   xref="x", yref="y",
                   layer="below")
    _merge!(image; kwargs...)
    push!(p.layout.images, image)
    p
end
