# cf https://github.com/JuliaMath/InverseFunctions.jl/blob/master/src/inverse.jl

import SimpleExpressions: hassymbolic, issymbolic
import SimpleExpressions: AbstractSymbolic, Symbolic, SymbolicNumber, SymbolicParameter, SymbolicExpression, SymbolicEquation



"""
    solve(ex::SymbolicEquation)

Tries to solve a symbolic equation by applying applicable identity functions.

Pretty limited, for example, can't solve `x^2 + x ~ 0`.

# Example

```julia
_solve = SimpleExpressions.solve
@symbolic x p

eqn = exp(x) ~ 1//2
_solve(eqn)  # x ~ log(1//2)

eqn = sin(x) + 2 ~ 3/2
_solve(eqn)  # x ~ -0.5235987755982989

t1,v1,v2 = p[1], p[2], p[3]
_solve(sin(t1)/v1 ~ sin(x)/v2) # x ~ asin((sin(p[1]) / p[2]) * p[3])
```

Some expressions hold symbolic numbers, such as the first example. The numeric value of the resulting equation `u` can be found through `u.rhs()`.


"""
function Roots.CommonSolve.solve(ex::SymbolicEquation)
    l, r = ex.lhs, ex.rhs
    nex = nothing
    if !hassymbolic(r)
        a,op = inverse(l)
        op != identity && (nex = a ~ op(r))
    elseif !hassymbolic(l)
        a,op = inverse(r)
        op != identity && (nex =  a ~ op(l))
    end
    isnothing(nex) && return(ex)
    solve(nex)
end


inverse(ex::SymbolicExpression) = inverse(ex.op, ex.arguments)

# inverse of outer(inner) returns
# inner, x -> outer⁻¹
# or errors
inverse(a::Any) = (a, identity)
inverse(x::Symbolic) = (x, identity)
inverse(p::SymbolicParameter) = (p, identity)

function inverse(::typeof(+), args)
    a, b = args # unary?
    hassymbolic(a) && !hassymbolic(b) && return (a, Base.Fix2(-,b))
    hassymbolic(b) && !hassymbolic(a) && return (b, Base.Fix2(-,a))

    throw(ArgumentError("Can't solve"))
end

function inverse(::typeof(-), args)

    length(args) == 1 && return (only(args), Base.Fix2(*,-1))

    a, b = args # binary
    hassymbolic(a) && !hassymbolic(b) && return (a, Base.Fix2(+,b))
    hassymbolic(b) && !hassymbolic(a) && return (b, Base.Fix2(*, -1) ∘ Base.Fix2(-,a))

    throw(ArgumentError("Can't solve"))
end

function inverse(::typeof(*), args)

    a, b = args # binary
    hassymbolic(a) && !hassymbolic(b) && return (a, Base.Fix2(/,b))
    hassymbolic(b) && !hassymbolic(a) && return (b, Base.Fix2(/,a))

    throw(ArgumentError("Can't solve"))
end

function inverse(::typeof(/), args)
    a, b = args # binary
    hassymbolic(a) && !hassymbolic(b) && return(a,  Base.Fix2(*,b))
    hassymbolic(b) && !hassymbolic(a) && return (b, inv ∘ Base.Fix2(*,a))

    throw(ArgumentError("Can't solve"))
end



##

inverse(::typeof(deg2rad), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, rad2deg(𝑦)))
inverse(::typeof(rad2deg), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, deg2rad(𝑦)))

inverse(::typeof(exp), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, log(𝑦)))
inverse(::typeof(log), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, exp(𝑦)))

inverse(::typeof(exp2), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, log2(𝑦)))
inverse(::typeof(log2), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, exp2(𝑦)))


inverse(::typeof(exp10), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, log10(𝑦)))
inverse(::typeof(log10), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, exp10(𝑦)))

inverse(::typeof(expm1), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, log1p(𝑦)))
inverse(::typeof(log1p), args) = (𝑥=only(args); 𝑦=Symbolic(:𝑦); (𝑥, expm1(𝑦)))

inverse(::typeof(sqrt), args) = (𝑥 =only(args); 𝑦=Symbolic(:𝑦); (𝑥, 𝑦^2))
inverse(::typeof(cbrt), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, 𝑦^3))

function inverse(::typeof(^), args)
    # XXX
    a, b = args
    !issymbolic(b) && return (a, a^(1/b))
    !issymbolic(a) && return (b, log(b) / log(a))
    throw(ArgumentError("Can't find inverse"))
end

inverse(::typeof(sin), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥,asin(𝑦)))
inverse(::typeof(asin), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, sin(𝑦)))
inverse(::typeof(cos), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, acos(𝑦)))
inverse(::typeof(acos), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥,cos(𝑦)))
inverse(::typeof(tan), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, atan(𝑦)))
inverse(::typeof(atan), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, tan(𝑦)))

inverse(::typeof(sinh), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, asinh(𝑦)))
inverse(::typeof(asinh), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, sinh(𝑦)))
inverse(::typeof(cosh), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, acosh(𝑦)))
inverse(::typeof(acosh), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, cosh(𝑦)))
inverse(::typeof(tanh), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, atanh(𝑦)))
inverse(::typeof(atanh), args) = (𝑥 = only(args); 𝑦=Symbolic(:𝑦); (𝑥, tanh(𝑦)))
