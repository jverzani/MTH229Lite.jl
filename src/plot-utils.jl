## plotif
function identify_colors(g, xs, colors=(:red, :blue, :black))
    F = (a,b) -> begin
        ga,gb=g(a),g(b)
        ga * gb < 0 && return nothing
        ga >= 0 && return true
        return false
    end
    find_colors(F, xs, colors)
end

# F(a,b) returns true, false, or nothing
function find_colors(F, xs, colors=(:red, :blue, :black))
    n = length(xs)
    cols = repeat([colors[1]], n)
    for i in 1:n-1
        a,b = xs[i], xs[i+1]
        val = F(a,b)
        if val == nothing
            cols[i] = colors[3]
        elseif val
            cols[i] = colors[1]
        else
            cols[i] = colors[2]
        end
    end
        cols[end] = cols[end-1]
    cols
end

# from stats base
function rle(v::Vector{T}) where {T}
    n = length(v)
    vals = T[]
    lens = Int[]

    n>0 || return (vals,lens)

    cv = v[1]
    cl = 1

    i = 2
    @inbounds while i <= n
        vi = v[i]
        if vi == cv
            cl += 1
        else
            push!(vals, cv)
            push!(lens, cl)
            cv = vi
            cl = 1
        end
        i += 1
    end

    # the last section
    push!(vals, cv)
    push!(lens, cl)

    return (vals, lens)
end


## -----
import .PlotlyLightLite: plot, plot!, implicit_plot, implicit_plot!
import .PlotlyLightLite: _new_plot

"""
    plotif(f, g, a, b)

Plot `f` colored depending on `g > 0` or `g < 0`.
"""
function plotif(f,g, a, b; width=800, height=600,
                kwargs...)
    N = 251
    xs = collect(range(a, b, length=N))
    cs = identify_colors(g, xs)
    cols, l = rle(cs)
    xs′ = cumsum(l); pushfirst!(xs′, 1)
    p = _new_plot(;width, height, legend=false, kwargs...)
    for i ∈ eachindex(cols)
	us = xs[xs′[i]:xs′[i+1]]
	push!(p.data, Config(x=us, y=f.(us),
                             mode="lines", line=Config(color=cols[i])))
	end
    p
end
plotif(f, g, I::Interval; kwargs...) = plotif(f, g, I...; kwargs...)


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

"""
    implicit_plot::SymbolicEquation

For equation written as `F(x,y(x)) = 0` plot implicitly defined `y`.

## Example

We simply use the symbolic parameter for the second variable

```
@symbolic u v
eq = u * v ~ u^3 + u^2 + u + 1

implicit_plot(eq)
```

To paramemterize a plot takes a bit of work to get the `(x,y)` values passed to the symbolic expression as a container in the first position:

```
@symbolic x p
u, v = x[1], x[2]
c,d,e,h = (p[i] for i in 1:4)
eq = u * v ~ c*u^3 + d*u^2 + e*u + h

implicit_plot((x,y) -> eq(tuple(x,y), (1,1,1,1)))
```
"""
implicit_plot(eq::SimpleExpressions.SymbolicEquation; kwargs...) =
    implicit_plot(eq.lhs - eq.rhs; kwargs...)

implicit_plot!(p::Plot, eq::SimpleExpressions.SymbolicEquation; kwargs...) =
    implicit_plot!(p, eq.lhs - eq.rhs; kwargs...)

implicit_plot!(eq::SimpleExpressions.SymbolicEquation; kwargs...) =
    implicit_plot!(current(), eq; kwargs...)
