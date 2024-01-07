## --- plotting

## create a Plots.plot like interface for PlotlyLight.Plot

const current_plot = Ref{Plot}()

"""
    plot(x, y; kwargs...)
    plot(f::Function, a, b; kwargs...)

Create a plot. Returns a `Plot` instance from [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl)

Keyword arguments include `width` and `height`, `xlims` and `ylims`, `legend`.

Provides an interface like `Plots.plot` for plotting a function `f` using `PlotlyLight`. This just scratches the surface, but `PlotLight` allows full acces to the underlying `JavaScript` [library](https://plotly.com/javascript/).

The provided "Plots" like functions are [`plot`](@ref), [`plot!`](@ref), [`scatter`](@ref), `scatter!`, [`annotate!`](@ref),  [`title!`](@ref), [`xlims!`](@ref) and [`ylims!`](@ref).

# Example

```
plot(sin, 0, 2pi)
plot!(cos)
x0 = [pi/4, 5pi/4]
scatter!(x0, sin.(x0), markersize=10)
title!("Sine and cosine and where they intersect in [0,2π]")
```
"""
function plot(x, y;
              kwargs...)
    p = Plot(Config(), Config(), Config() )
    current_plot[] = p
    plot!(p, x, y; kwargs...)
    p
end

function plot(f::Function, a::Real, b::Real;
              kwargs...)
    p = Plot(Config(), Config(), Config() )
    current_plot[] = p
    plot!(p, f, a, b; kwargs...)
    p
end

"""
    plot!([p::Plot], f; kwargs...)
    plot!([p::Plot], x, y; kwargs...)

Used to add a new tract to an existing plot. Like `Plots.plot!`
"""
function plot!(p::Plot, x, y;
               width=800, height=600,
               xlims=nothing, ylims=nothing,
               legend=false,
               kwargs...)

    size!(p, width=width, height=height)
    xlims!(p, xlims)
    ylims!(p, ylims)

    nans = findall(isnan, y)
    if !isempty(nans)
        l = 1
        for r ∈ nans
            idx = l:(r-1)
            l = r + 1
            length(idx) <= 0 && continue
            d, _ = plotly_config(x[idx], y[idx]; showlegend=legend, kwargs...)
            push!(p.data,d)
            l = r+1
        end
    else
        d, l = plotly_config(x,y; kwargs...)
        push!(p.data, d)
    end
    #merge!(p.layout, l)
    p
end

function plot!(p::Plot, f::Function, a, b; kwargs...)
    x,y = unzip(f, a, b)
    plot!(p, x, y; kwargs...)
end

function plot!(p::Plot, f::Function; kwargs...)
    m,M = (Inf, -Inf)
    for d ∈ p.data
        haskey(d, :x) || continue
        a,b = extrema(d.x)
        m = min(a, m); M = max(b,M)
    end
    plot!(p, f, m, M; kwargs...)
end

plot!(x, y; kwargs...) =  plot!(current_plot[], x, y; kwargs...)
plot!(f::Function; kwargs...) =  plot!(current_plot[], f; kwargs...)

"""
    scatter(x, y; markershape, markercolor, markersize, kwargs...)
    scatter!([p::Plot], x, y; kwargs...)

Place point on a plot.
* `markershape`: shape, e.g. "diamond" or "diamond-open"
* `markercolor`: color e.g. "red"
* `markersize`:  size, as an integer
"""
function scatter(x, y; kwargs...)
    p = Plot()
    current_plot[] = p
    scatter!(p, x, y; kwargs...)
    p
end

function scatter!(p::Plot, x, y;
                  markershape = nothing,
                  markersize = nothing,
                  markercolor = nothing,
                  kwargs...)
    cfg, l = plotly_config(x, y; series="markers", type="scatter")
    !isnothing(markershape) && (cfg.marker.symbol = markershape)
    !isnothing(markersize) && (cfg.marker.size = markersize)
    !isnothing(markercolor) && (cfg.marker.color = markercolor)

    push!(p.data, cfg)
    p
end
scatter!(x, y; kwargs...) = scatter!(current_plot[], x, y; kwargs...)


"""
    annotate!([p::Plot], x, y, txt; size, color, textposition, kwargs...)
    annotate!([p::Plot], anns::Tuple; size, color, textposition, kwargs...)

Add annotations to plot
* size: text size
* color: text color
* textposition: one of "top", "bottom", "left", "right", or combinations with `_`
"""
function annotate!(p::Plot, x, y, txt;
                   size = nothing,
                   color= nothing,
                   textposition = nothing,
                   kwargs...)

    cfg, l = plotly_config(x, y; text=txt, mode="text")
    !isnothing(size) && (cfg.textfont.size=size)
    !isnothing(color) && (cfg.textfont.color=color)
    !isnothing(textposition) && (cfg.textposition = textposition)

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

function size!(p::Plot; width=nothing, height=nothing)
    !isnothing(width) && (p.layout.width=width)
    !isnothing(height) && (p.layout.height=height)
    p
end
size!(;width=nothing, height=nothing) = size(current_plot[]; width, height)

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


# clean arguments from Plots wiht line attributes
function plotly_config(x,y=nothing;
                       linewidth=nothing,
                       series = nothing,
                       type = nothing,
                       mode = nothing,
                       linecolor = nothing,
                       ## layout options
                       legend = nothing,
                       kwargs...)
    c = Config(;x)
    c.line = Config()
    !isnothing(y) && (c.y = y)

    !isnothing(linewidth) && (c.line.width=linewidth)
    !isnothing(series) && (c.mode = series)
    !isnothing(type) && (c.type = type)
    !isnothing(mode) && (c.mode = mode)
    !isnothing(linecolor) && (c.line.color=linecolor)

    for (k, v) ∈ kwargs
        c[k] = v
    end

    l = Config()
    !isnothing(legend) && (l.showlegend = legend)

    c, l
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
