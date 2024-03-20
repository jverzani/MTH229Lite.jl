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
