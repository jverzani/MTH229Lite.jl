# Find roots of a polynomial
function polynomial_roots(u::AbstractSymbolic; kwargs...)
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
function polynomial_coeffs(u::AbstractSymbolic)
    𝑥 = _Polynomial((0,1))
    p = try
        u(𝑥)
    catch err
        throw(ArgumentError("Not a polynomial"))
    end
    [get(p.coeffs,i,0) for i ∈ 0:maximum(keys(p.coeffs))]
end

function is_polynomial(u::AbstractSymbolic)
    try
        polynomial_coeffs(u)
        true
    catch err
        false
    end
end

# return solutions as vector
function solve_polynomial(p::AbstractSymbolic)
    cs = polynomial_coeffs(p)
    d = length(cs) - 1
    d == 1 && return [-cs[1]/cs[2]]
    if d == 2
        c, b, a = cs
        Δ = b^2 - 4*a*c
        Δ = issymbolic(Δ) ? Δ : SymbolicNumber(Δ)
        return (-b .+ [sqrt(Δ), -sqrt(Δ)]) ./ (2a)
    end
    if d == 3
        ps₀, ps₁, ps₂, ps₃ = cs
        u1 = -ps₂/(3*ps₃) - (-3*ps₁/ps₃ + ps₂^2/ps₃^2)/(3*cbrt(27*ps₀/(2*ps₃) - 9*ps₁*ps₂/(2*ps₃^2) + ps₂^3/ps₃^3 + sqrt(-4*(-3*ps₁/ps₃ + ps₂^2/ps₃^2)^3 + (27*ps₀/ps₃ - 9*ps₁*ps₂/ps₃^2 + 2*ps₂^3/ps₃^3)^2)/2)) - cbrt(27*ps₀/(2*ps₃) - 9*ps₁*ps₂/(2*ps₃^2) + ps₂^3/ps₃^3 + sqrt(-4*(-3*ps₁/ps₃ + ps₂^2/ps₃^2)^3 + (27*ps₀/ps₃ - 9*ps₁*ps₂/ps₃^2 + 2*ps₂^3/ps₃^3)^2)/2)/3
        u2 = -ps₂/(3*ps₃) - (-3*ps₁/ps₃ + ps₂^2/ps₃^2)/(3*(-1/2 - sqrt(3)*I/2)*cbrt(27*ps₀/(2*ps₃) - 9*ps₁*ps₂/(2*ps₃^2) + ps₂^3/ps₃^3 + sqrt(-4*(-3*ps₁/ps₃ + ps₂^2/ps₃^2)^3 + (27*ps₀/ps₃ - 9*ps₁*ps₂/ps₃^2 + 2*ps₂^3/ps₃^3)^2)/2)) - (-1/2 - sqrt(3)*I/2)*cbrt(27*ps₀/(2*ps₃) - 9*ps₁*ps₂/(2*ps₃^2) + ps₂^3/ps₃^3 + sqrt(-4*(-3*ps₁/ps₃ + ps₂^2/ps₃^2)^3 + (27*ps₀/ps₃ - 9*ps₁*ps₂/ps₃^2 + 2*ps₂^3/ps₃^3)^2)/2)/3
        u3 = -ps₂/(3*ps₃) - (-3*ps₁/ps₃ + ps₂^2/ps₃^2)/(3*(-1/2 + sqrt(3)*I/2)*cbrt(27*ps₀/(2*ps₃) - 9*ps₁*ps₂/(2*ps₃^2) + ps₂^3/ps₃^3 + sqrt(-4*(-3*ps₁/ps₃ + ps₂^2/ps₃^2)^3 + (27*ps₀/ps₃ - 9*ps₁*ps₂/ps₃^2 + 2*ps₂^3/ps₃^3)^2)/2)) - (-1/2 + sqrt(3)*I/2)*cbrt(27*ps₀/(2*ps₃) - 9*ps₁*ps₂/(2*ps₃^2) + ps₂^3/ps₃^3 + sqrt(-4*(-3*ps₁/ps₃ + ps₂^2/ps₃^2)^3 + (27*ps₀/ps₃ - 9*ps₁*ps₂/ps₃^2 + 2*ps₂^3/ps₃^3)^2)/2)/3
        return [u1, u2, u3]
    end
    # d ≥ 4 use roots approach
    comp = companion(collect(Float64, cs))
    return eigvals(comp)
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
const NUMBER = Union{Number, SymbolicParameter, SymbolicNumber}

# scalar
function Base.:+(p::_Polynomial, c::NUMBER)
    d = deepcopy(p.coeffs)
    d[0] = get(d,0,0) + c
    _Polynomial(p.x, d)
end
Base.:+(c::NUMBER, p::_Polynomial) = p + c
function Base.:(-)(p::_Polynomial, c::NUMBER) # should just be p + (-c)??
    d = deepcopy(p.coeffs)
    d[0] = get(d,0,0) - c
    _Polynomial(p.x, d)
end
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
        u = pₖ + v
        d[k] = pₖ + v
    end
    _Polynomial(p.x,d)
end

Base.:(-)(p::_Polynomial, q::_Polynomial) = p + (-q)

function Base.:(*)(p::_Polynomial, q::_Polynomial)
    pq = _Polynomial()
    for (k,v) ∈ p.coeffs
        for (l,w) ∈ q.coeffs
            m = k + l
            a = get(pq.coeffs, k+l, 0)
            b = v * w
            pq.coeffs[k+l] = get(pq.coeffs, k+l, 0) + (v*w)
        end
    end
    pq
end
