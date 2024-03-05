function _merge!(c::Config; kwargs...)
    for kv ∈ kwargs
        k,v = kv
        v = isa(v,Pair) ? last(v) : v
        isnothing(v) && continue
        c[k] = v
    end
end
function _merge!(c::Config, d::Config)
    for (k, v) ∈ d
        c[k] = v
    end
end

function _join!(xs, delim="")
    xs′ = filter(!isnothing, xs)
    isempty(xs′) && return nothing
    join(string.(xs′), delim)
end

# helper
_adjust_matrix(m::Matrix) = collect(eachrow(m))
_adjust_matrix(x::Any) = x

# from some.jl
_something() = nothing
_something(x::Nothing, xs...) = _something(xs...)
_something(x::Any, xs...) = x
# from Missing.jl

_allowmissing(x::AbstractArray{T}) where {T} = convert(AbstractArray{Union{T, Missing}}, x)

## ----
function Base.extrema(p::Plot)
    mx,Mx = (Inf, -Inf)
    my,My = (Inf, -Inf)
    mz,Mz = (Inf, -Inf)
    for d ∈ p.data
        if haskey(d, :x)
            a,b = extrema(d.x)
            mx = min(a, mx); Mx = max(b, Mx)
        end
        if haskey(d, :y)
            a,b = extrema(filter(!isnothing, d.y))
            my = min(a, my); My = max(b, My)
        end
        if haskey(d, :z)
            a,b = extrema(d.z)
            mz = min(a, mz); Mz = max(b, Mz)
        end

    end
    x = isempty(p.layout.xaxis.range) ? (mx,Mx) : p.layout.xaxis.range
    y = isempty(p.layout.yaxis.range) ? (my,My) : p.layout.yaxis.range
    z = isempty(p.layout.zaxis.range) ? (mz,Mz) : p.layout.zaxis.range
    (; x, y, z)
end

struct Recycler{T}
    itr::T
    n::Int
end
Recycler(x) =  Recycler(x, length(x))
Recycler(::Nothing) =  Recycler([nothing],1)

function Base.getindex(R::Recycler, i::Int)
    q, r = divrem(i, R.n)
    idx = iszero(r) ? R.n : r
    R.itr[idx]
end

## -----
# what is a good heuristic to identify vertical lines?
## -----
include("SplitApplyCombine_invert.jl")

"""
    unzip(v, [vs...])
    unzip(f::Function, a, b)
    unzip(a, b, F::Function)

Reshape data to x,y,[z] mode.

In its basic use, `zip` takes two vectors, pairs them off, and returns an iterator of tuples for each pair. For `unzip` a vector of same-length vectors is "unzipped" to return two (or more) vectors.

The function version applies `f` to a range of points over `(a,b)` and then calls `unzip`. This uses the `adapted_grid` function from `PlotUtils`.

The function version with `F` computes `F(a', b)` and then unzips. This is used with parameterized surface plots

This uses the `invert` function of `SplitApplyCombine`.
"""
unzip(vs) = invert(vs) # use SplitApplyCombine.invert (copied below)
unzip(vs::Base.Iterators.Zip) = vs.is
#unzip(v,vs...) = unzip([v, vs...])
unzip(r::Function, a, b, n) = unzip(r.(range(a, stop=b, length=n)))
# return (xs, f.(xs)) or (f₁(xs), f₂(xs), ...)
function unzip(f::Function, a, b)
    n = length(f(a))
    if n == 1
        return PlotUtils.adapted_grid(f, (a,b))
    else
        xsys = [PlotUtils.adapted_grid(x->f(x)[i], (a,b)) for i ∈ 1:n]
        xs = sort(vcat([xsys[i][1] for i ∈ 1:n]...))
        return unzip(f.(xs))
    end

end
# return matrices for x, y, [z]
unzip(as, bs, F::Function) = unzip(F.(as', bs))
