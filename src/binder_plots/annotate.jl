

## ----

# function annotate!(p::Plot, x, y, txt;
#                    color= nothing,
#                    family = nothing,
#                    pointsize = nothing,
#                    halign = nothing,
#                    valign = nothing,
#                    rotation = nothing,
#                    kwargs...)

#     cfg = Config(; x, y, text=txt, mode="text", type="scatter")

#     textposition = _something(strip(join(something.((halign, valign), ""), " ")))
#     _merge!(cfg; textposition)
#     _textstyle!(cfg.textfont; color, family, pointsize, rotation,  kwargs...)

#     push!(p.data, cfg)
#     p
# end

# annotate!(p::Plot, anns::Tuple; kwargs...) = annotate!(p, unzip(anns)...; kwargs...)
# annotate!(p::Plot, anns::Vector; kwargs...) = annotate!(p, unzip(anns)...; kwargs...)
# annotate!(x, y, txt; kwargs...) = annotate!(current_plot[], x, y, txt; kwargs...)
# annotate!(anns::Tuple; kwargs...) = annotate!(current_plot[], anns; kwargs...)
# annotate!(anns::Vector; kwargs...) = annotate!(current_plot[], anns; kwargs...)

struct Text{S,F}
    str::S
    font::F
end
text(str, args...; kwargs...) = Text(str, font(args...; kwargs...))
text(t::Text, args...; kwargs...) = t

struct Font{F,PS,HA,VA,R,C}
    family::F
    pointsize::PS
    halign::HA
    valign::VA
    rotation::R
    color::C
end

"""
    font(args...)

(This if from Plots.jl)

Create a Font from a list of features. Values may be specified either as
arguments (which are distinguished by type/value) or as keyword arguments.

# Arguments

- `family`: AbstractString. "serif" or "sans-serif" or "monospace"
- `pointsize`: Integer. Size of font in points
- `halign`: Symbol. Horizontal alignment (:hcenter, :left, or :right)
- `valign`: Symbol. Vertical alignment (:vcenter, :top, or :bottom)
- `rotation`: Real. Angle of rotation for text in degrees (use a non-integer type)
- `color`
# Examples
```julia-repl
julia> font(8)
julia> font(family="serif", halign=:center, rotation=45.0)
```
"""
function font(args...;
              family="sans-serif",
              pointsize = 14,
              halign = nothing,
              valign = nothing,
              rotation = 0,
              color = "black"
              )

    for a ∈ args
        # string is family
        isa(a, AbstractString) && (family = a)
        # pointsize or rotation
        if isa(a, Real)
            if isa(a, Integer)
                pointsize = a
            else
                rotation = a
            end
        end
        # symbol is color or alignment
        if isa(a, Symbol)
            if a ∈ (:top, :bottom,:center)
                valign = a
            elseif a ∈ (:left, :right)
                halign = a
            else
                color=a
            end
        end
    end

    Font(family, pointsize, halign, valign, rotation, color)
end


_align(::Nothing, x::Symbol) = string(x)
_align(x::Symbol, ::Nothing) = string(x)
_align(::Nothing, ::Nothing) = ""
_align(x::Symbol, y::Symbol) = join((string(x), string(y)), " ")

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
                   kwargs...)

    # txt may be string or 'text' objects
    # convert string to text object then ...
    tfs = [text(tᵢ) for tᵢ ∈ txt]
    _txt = [t.str for t in tfs]
    family = [t.font.family for t in tfs]
    pointsize = [t.font.pointsize for t in tfs]
    textposition = [_align(t.font.valign, t.font.halign) for t in tfs]
    rotation = [t.font.rotation for t in tfs]
    color = [t.font.color for t in tfs]

    cfg = Config(; x, y, text=_txt, mode="text", type="scatter", textposition)
    _textstyle!(cfg.textfont; color, family, pointsize, rotation, kwargs...)

    push!(p.data, cfg)
    p
end

annotate!(p::Plot, anns::Tuple; kwargs...) = annotate!(p, unzip(anns)...; kwargs...)
annotate!(p::Plot, anns::Vector; kwargs...) = annotate!(p, unzip(anns)...; kwargs...)
annotate!(x, y, txt; kwargs...) = annotate!(current_plot[], x, y, txt; kwargs...)
annotate!(anns::Tuple; kwargs...) = annotate!(current_plot[], anns; kwargs...)
annotate!(anns::Vector; kwargs...) = annotate!(current_plot[], anns; kwargs...)

## ----

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
