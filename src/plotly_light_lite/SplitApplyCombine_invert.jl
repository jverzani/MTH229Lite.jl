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
struct Indexer{i}
end

Indexer(i::Int) = Indexer{i}()
(::Indexer{i})(x) where {i} = @inbounds x[i]

# Array-Tuple
@inline function invert(a::AbstractArray{<:NTuple{n, Any}}) where {n}
    if @generated
        exprs = [ :(map($(Indexer(i)), a)) for i in 1:n ]
        return :( tuple($(exprs...)) )
    else
        ntuple(i -> map(x -> x[i], a), Val(n))
    end
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
