# Find roots of a polynomial
function polynomial_roots(u::SimpleExpressions.AbstractSymbolic; kwargs...)
    comp = companion(collect(Float64, polynomial_coeffs(u)))
    eigvals(comp; kwargs...)
end

## -----
# get polynomial coefficients of symbolic expression
struct _Polynomial
    x::Symbol
    coeffs::Dict{Int, Any} # non performant
end

# get polynomial coefficients or throw error
function polynomial_coeffs(u::SimpleExpressions.AbstractSymbolic)
    𝑥 = _Polynomial((0,1))
    p = try
        u(𝑥)
    catch err
        throw(ArgumentError("Not a polynomial"))
    end
    [get(p.coeffs,i,0) for i ∈ 0:maximum(keys(p.coeffs))]
end

function is_polynomial(u::SimpleExpressions.AbstractSymbolic)
    try
        polynomial_coeffs(u)
        true
    catch err
        false
    end
end

function companion(coeffs::Vector{T}) where {T}
    d = length(coeffs) - 1
    isone(d) && throw(ArgumentError("Too small"))
    d == 2 && return diagm(0 => [-coeffs[1] / coeffs[2]])

    R = eltype(one(T)/one(T))
    comp = diagm(-1 => ones(R, d - 1))
    ani = 1 / coeffs[end]
    for j in  0:(d-1)
        comp[1,(d-j)] = -coeffs[j+1] * ani # along top row has smaller residual than down column
    end
    return comp
end



##

function _Polynomial(coeffs=(0,), x::Symbol=:x)
    d = Dict{Int, Any}()
    for (i, xᵢ) ∈ enumerate(coeffs)
        d[i-1] = xᵢ
    end
    _Polynomial(x, d)
end

function Base.show(io::IO, x::_Polynomial)
    print(io, "Polynomial in $(x.x)")
    println(io, x.coeffs)
end
function Base.map(fn, p::_Polynomial)
    d = deepcopy(p.coeffs)
    for (k,v) ∈ d
        d[k] = fn(v)
    end
    _Polynomial(p.x,d)
end

# unary
Base.:-(p::_Polynomial) = map(x -> -x, p)
const NUMBER = Union{Number, SimpleExpressions.SymbolicParameter}

# scalar
function Base.:+(p::_Polynomial, c::NUMBER)
    d = deepcopy(p.coeffs)
    d[0] = get(d,0,0) + c
    _Polynomial(p.x, d)
end
Base.:+(c::NUMBER, p::_Polynomial) = p + c
Base.:(-)(p::_Polynomial, c::NUMBER) = p + (-c)
Base.:-(c::NUMBER, p::_Polynomial) = (-p) + c
Base.:(*)(p::_Polynomial, c::NUMBER) = map(x -> x*c, p)
Base.:(*)(c::NUMBER, p::_Polynomial) = map(x -> c*x, p)
Base.:(/)(p::_Polynomial, c::NUMBER) = map(x -> x/c, p)

function Base.:(^)(p::_Polynomial, n::Int)
    n < 0 && throw(ArgumentError("Negative power"))
    if iszero(n)
        empty!(p.coeffs)
        p.coeffs[0] = 1
        return p
    end
    isone(n) && return p
    Base.power_by_squaring(p, n)
end


function Base.:(+)(p::_Polynomial, q::_Polynomial)
    d = deepcopy(p.coeffs)
    for (k,v) ∈ q.coeffs
        pₖ = get(p.coeffs, k, 0)
        d[k] = pₖ + v
    end
    _Polynomial(p.x,d)
end

Base.:(-)(p::_Polynomial, q::_Polynomial) = p + (-q)

function Base.:(*)(p::_Polynomial, q::_Polynomial)
    pq = _Polynomial()
    for (k,v) ∈ p.coeffs
        for (l,w) ∈ q.coeffs
            pq.coeffs[k+l] = get(pq.coeffs, k+l, 0) + v*w
        end
    end
    pq
end
