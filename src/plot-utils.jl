"""
    unzip(v, [vs...])
    unzip(f::Function, a, b)

Take container of points, return vector of corrodinated. Reverse of `zip`. Function version applies `f` to a range of points over `(a,b)` and then calls `unzip`.
"""
unzip(vs) = invert(vs)
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

## ----
## This is lifted from SplitApplyCombine
@inline function invert(a::AbstractArray{T}) where {T <: AbstractArray}
    f = first(a)
    innersize = size(a)
    outersize = size(f)
    innerkeys = keys(a)
    outerkeys = keys(f)

    @boundscheck for x in a
        if size(x) != outersize
            error("keys don't match")
        end
    end

    out = Array{Array{eltype(T),length(innersize)}}(undef, outersize)
    @inbounds for i in outerkeys
        out[i] = Array{eltype(T)}(undef, innersize)
    end

    return _invert!(out, a, innerkeys, outerkeys)
end

function invert!(out::AbstractArray, a::AbstractArray)
    innerkeys = keys(a)
    outerkeys = keys(first(a))

    @boundscheck for x in a
        if keys(x) != outerkeys
            error("keys don't match")
        end
    end

    @boundscheck if keys(out) != outerkeys
        error("keys don't match")
    end

    @boundscheck for x in out
        if keys(x) != innerkeys
            error("keys don't match")
        end
    end

    return _invert!(out, a, innerkeys, outerkeys)
end

# Note: keys are assumed verified already
function _invert!(out, a, innerkeys, outerkeys)
    @inbounds for i ∈ innerkeys
        tmp = a[i]
        for j ∈ outerkeys
            out[j][i] = tmp[j]
        end
    end
    return out
end

# Tuple-tuple
@inline function invert(a::NTuple{n, NTuple{m, Any}}) where {n, m}
    if @generated
        exprs = [:(tuple($([:(a[$j][$i]) for j in 1:n]...))) for i in 1:m]
        return :(tuple($(exprs...)))
    else
        ntuple(i -> ntuple(j -> a[j][i], Val(n)), Val(m))
    end
end


# Tuple-Array
@inline function invert(a::NTuple{n, AbstractArray}) where {n}
    arrayinds = keys(a[1])

    @boundscheck for x in a
        if keys(x) != arrayinds
            error("indices are not uniform")
        end
    end

    T = _eltypes(typeof(a))
    out = similar(first(a), T)

    @inbounds invert!(out, a)
end

@inline function invert!(out::AbstractArray{<:NTuple{n, Any}}, a::NTuple{n, AbstractArray}) where n
    @boundscheck for x in a
        if keys(x) != keys(out)
            error("indices do not match")
        end
    end

    if @generated
        return quote
            @inbounds for i in keys(out)
                out[i] = $(:(tuple($([:( a[$j][i] ) for j in 1:n]...))))
            end

            return out
        end
    else
        @inbounds for i in keys(out)
            out[i] = map(x -> @inbounds(x[i]), a)
        end

        return out
    end
end

## -----
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
