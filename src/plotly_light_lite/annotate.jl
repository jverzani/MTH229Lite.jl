

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
    _textstyle!(cfg.textfont; color, family, pointsize, rotation, textposition, kwargs...)

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
