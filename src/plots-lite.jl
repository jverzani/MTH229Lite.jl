## --- plotting

## create a Plots.plot like interface for PlotlyLight.Plot

const current_plot = Ref{Plot}()
const first_plot = Ref{Bool}(true)

"""
    plot(x, y; [linecolor], [linewidth], [legend], kwargs...)
    plot(f::Function, a, b; kwargs...)

Create a line plot.

Returns a `Plot` instance from [PlotlyLight](https://github.com/JuliaComputing/PlotlyLight.jl)

* x,y points to plot. NaN values in `y` break the line
* linecolor: color of line
* linewidth: width of line

Other keyword arguments include `width` and `height`, `xlims` and `ylims`, `legend`.

Provides an interface like `Plots.plot` for plotting a function `f` using `PlotlyLight`. This just scratches the surface, but `PlotlyLight` allows full access to the underlying `JavaScript` [library](https://plotly.com/javascript/).

The provided "Plots" like functions are [`plot`](@ref), [`plot!`](@ref), [`scatter!`](@ref), `scatter`, [`annotate!`](@ref),  [`title!`](@ref), [`xlims!`](@ref) and [`ylims!`](@ref).

# Example

```
plot(sin, 0, 2pi; legend=false)
plot!(cos)
x0 = [pi/4, 5pi/4]
scatter!(x0, sin.(x0), markersize=10)
annotate!(tuple(zip(x0, sin.(x0), ("A", "B"))...), halign="left", pointsize=12)
title!("Sine and cosine and where they intersect in [0,2π]")
```

!!! note "Warning"
    You may need to run the first plot cell twice to see an image.
"""
function plot(x, y; kwargs...)
    p = _new_plot(; kwargs...)
    plot!(p, x, y; kwargs...)
    p
end

function plot(f::Function, a::Real, b::Real;
              kwargs...)
    p = _new_plot(;kwargs...)
    plot!(p, f, a, b; kwargs...)
    p
end


# make a new plot
function _new_plot(;
                   width=800, height=600,
                   xlims=nothing, ylims=nothing,
                   kwargs...)
    p = Plot(Config(), Config(), Config() )

    size!(p, width=width, height=height)
    xlims!(p, xlims)
    ylims!(p, ylims)


    current_plot[] = p
    if first_plot[]
        @info "For the first plot, you may need to re-run your command to see the plot"
        first_plot[] = false
    end
    p
end



"""
    plot!([p::Plot], f; kwargs...)
    plot!([p::Plot], x, y; kwargs...)

Used to add a new tract to an existing plot. Like `Plots.plot!`
"""
function plot!(p::Plot, x, y;
               linecolor=nothing,
               linewidth = nothing,
               legend=nothing,
               kwargs...)


    nans = findall(isnan, y)
    if !isempty(nans)
        l = 1
        for r ∈ nans
            idx = l:(r-1)
            l = r + 1
            length(idx) <= 0 && continue
            c = Config(x = x[idx], y=y[idx])
            !isnothing(linewidth) && (c.line.width=linewidth)
            !isnothing(linecolor) && (c.line.color=linecolor)

            push!(p.data,c)
            l = r+1
        end
    else
        c = Config(; x, y)
        !isnothing(linewidth) && (c.line.width=linewidth)
        !isnothing(linecolor) && (c.line.color=linecolor)

        push!(p.data, c)
    end

    # layout
    legend!(p, legend)
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
    scatter(x, y; [markershape], [markercolor], [markersize], kwargs...)
    scatter!([p::Plot], x, y; kwargs...)

Place point on a plot.
* `markershape`: shape, e.g. "diamond" or "diamond-open"
* `markercolor`: color e.g. "red"
* `markersize`:  size, as an integer
"""
function scatter!(p::Plot, x, y;
                  markershape = nothing,
                  markersize = nothing,
                  markercolor = nothing,
                  legend=nothing,
                  kwargs...)

    cfg = Config(;x, y, mode="markers", type="scatter")
    !isnothing(markershape) && (cfg.marker.symbol = markershape)
    !isnothing(markersize)  && (cfg.marker.size = markersize)
    !isnothing(markercolor) && (cfg.marker.color = markercolor)

    push!(p.data, cfg)

    # layout
    legend!(p, legend)

    p
end
scatter!(x, y; kwargs...) = scatter!(current_plot[], x, y; kwargs...)

function scatter(x, y; kwargs...)
    p = _new_plot(; kwargs...)
    scatter!(p, x, y; kwargs...)
    p
end


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
"""
function annotate!(p::Plot, x, y, txt;
                   color= nothing,
                   family = nothing,
                   pointsize = nothing,
                   halign = nothing,
                   valign = nothing,
                   kwargs...)

    cfg = Config(; x, y, text=txt, mode="text", type="scatter")

    textposition = something(halign,"") * something(valign, "")
    isempty(textposition) && (textposition = nothing)
    !isnothing(textposition) && (cfg.textposition = textposition)

    !isnothing(color) && (cfg.textfont.color=color)
    !isnothing(family) && (cfg.textfont.family = family)
    !isnothing(pointsize) && (cfg.textfont.size = pointsize)

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

legend!(p::Plot, legend=nothing) = !isnothing(legend) && (p.layout.showlegend = legend)

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

## -----
## Special case for plotting SymbolicEquations
function plot(ex::SimpleExpressions.SymbolicEquation, a::Real, b::Real; kwargs...)
    p = _new_plot(; kwargs...)
    plot!(p, ex, a, b; kwargs...)

end
plot(f::SimpleExpressions.SymbolicEquation, I::Interval; kwargs...) = plot(f, I.a, I.b; kwargs...)


function plot!(p::Plot, ex::SimpleExpressions.SymbolicEquation, a::Real, b::Real; kwargs...)
    lhs, rhs = ex.lhs, ex.rhs
    fl = SimpleExpressions.issymbolic(lhs) ? lhs : ((x) -> lhs)
    fr = SimpleExpressions.issymbolic(rhs) ? rhs : ((x) -> rhs)
    plot!(p, fl, a, b; kwargs...)
    plot!(p, fr, a, b; kwargs...)
    p
end
