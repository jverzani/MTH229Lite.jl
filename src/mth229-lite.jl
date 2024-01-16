# e
const e = exp(1)

# Derivatives
# f'
Base.adjoint(f::Function) = x -> ForwardDiff.derivative(f, float(x))
Base.adjoint(f::SimpleExpressions.AbstractSymbolic) = SimpleExpressions.D(f)
function D(f::Function)
    𝑥 = SimpleExpressions.Symbolic(:𝑥)
    SimpleExpressions.D(f(𝑥))
end

"""
    Interval(a,b)

A means to specify an interval in the  form `a..b`

There are methods for
* `plot(eq, I)` (two plots)
* `solve(eq, I)` (dispatch to find_zeros)
* `sign_chart`, `riemann`, `quadgk`

Rhere are parsing gotchas
* `-1..2` is okay
* `-2..-1` is not, try `-2..(-1)`
* `-1..x^2` will parse as `Interval(-1,x^2)`, also `-1..x+2` becomes `Interval(-1, x_1)`, as `..` has low precedence.
"""
struct Interval{T}
    a::T
    b::T
end
a..b = Interval(promote(a,b)...) # sort?
function Base.iterate(i::Interval, state=nothing)
    isnothing(state) && return (i.a, 1)
    state == 1 && return (i.b, 2)
    nothing
end
Base.length(::Interval) = 2
# solve just seems kind of natural here
# solve(eqn, I::Interval) -> find_zeros
# solve(eqn, x₀) find_zero
"""
    solve(ex::SymbolicEquation, x₀, args...; kwargs...)
    solve(ex::SymbolicEquation, x₀::Interval; kwargs...)`

Numerically solve an equation specified with an [`@symbolic`](@ref) value.

The `find_zero` or `find_zeros` function is used, the latter when `x₀` is of type `Interval` (specified with the `..` infix operator.

# Example
```julia
julia> solve(e^x ~ x^4, 10)       # solution near 10
8.6131694564414

julia> solve(e^x ~ x^4, -10, 10)  # some solution in bracketing interval
-0.8155534188089607

julia> solve(e^x ~ x^4, -10..10)  # all solutions within [-10, 10]
3-element Vector{Float64}:
 -0.8155534188089606
  1.4296118247255554
  8.6131694564414
```

"""
function Roots.CommonSolve.solve(ex::SimpleExpressions.SymbolicEquation, x₀, args...; kwargs...)
    find_zero(ex, x₀, args...; kwargs...)
end

function Roots.CommonSolve.solve(ex::SimpleExpressions.SymbolicEquation, I::Interval; kwargs...)
    find_zeros(ex, I; kwargs...)
end

## ----

# simple functions of MTH229

"`tangent(f,c)` returns a function computing the tangent line of `f` at `c`"
tangent(f, c) = x -> f(c) + f'(c)*(x-c)
tangent(u::SimpleExpressions.AbstractSymbolic,c) = (@symbolic 𝑥; u(c) + u'(c)*(𝑥-c))

"`secant(f,a,b)` returns a function computing the secant line of `f` between `a` and `b`"
secant(f, a, b) = x -> f(a) + (f(b)-f(a)) / (b-a) * (x - a)
function secant(f::SimpleExpressions.AbstractSymbolic, a, b)
    @symbolic 𝑥
    f(a) + (f(b)-f(a)) / (b-a) * (𝑥 - a)
end


"`fisheye(f)` changes domain of function `f` to `(-pi/2, pi/2)`"
fisheye(f)=x->atan(f(tan(x)))

"`rangeclamp(f, [hi], [lo]; replacement)` returns f function which has the value of `replacement` when `lo <= f(x) <= hi` doesn't hold."
rangeclamp(f, hi=20, lo=-hi; replacement=NaN) = x -> lo < f(x) < hi ? f(x) : replacement

"`newton(f, x)` easy to use Newton's method; derivative computed using `f'`"
newton(f, x; kwargs...) = find_zero((f, f'), x, Roots.Newton(); kwargs...)

"`bisection(f, a, b)` naive bisection algorithm with primitive graphic. Use `find_zero(f, (a,b))` (or `fzero(f, a, b)`) for a more robust method."
function bisection(f::Function, a, b)
    a,b = sort([a,b])

    if f(a) * f(b) > 0
        error("[a,b] is not a bracket. A bracket means f(a) and f(b) have different signs!")
    end

    M = a + (b-a) / 2


    i, j = 0, 64
    ss = fill("#", 65)
    ss[i+1]="a"; ss[j+1]="b"
    println("")
    println(join(ss))
    flag = true

    while a < M < b
        if flag && j-i == 1
            ss = fill(" ", 65)
            ss[j:(j+1)] .= "⋮"
            println(join(ss))
            println("")
            flag = false
        end


        if f(M) == 0.0
            println("... exact answer found ...")
	    break
        end
        ## update step
	if f(a) * f(M) < 0
	    a, b = a, M

            if flag
                j = div(i + j, 2)
            end


	else
	    a, b = M, b

            if flag
                i = div(i + j, 2)
            end

	end

        if flag
            ss = fill(".", 65)
            ss[i+1]="a"; ss[j+1]="b"; ss[(i+2):j] .= "#"
            println(join(ss))
        end

        M = a + (b-a) / 2
    end
    M
end

"`lim(f, c; [dir=\"-\"])` makes a table of values of `f` as `x` approaches `c`."
function lim(f::Function, c::Real; n::Int=6, dir="+")
    hs = [(1/10)^i for i in 1:n] # close to 0
    if dir == "+"
	xs = c .+ hs
    else
	xs = c .- hs
    end
    ys = map(f, xs)
    [xs ys]
end

"`signchart(f, a, b)` identifies zeros of `f` (or discontinuities which jump over `0` and classifies sign change at each"
function sign_chart(f, a, b; atol=1e-6)
    pm(x) = x < 0 ? "-" : x > 0 ? "+" : "0"
    summarize(f,cp,d) = (var"DNE_0_∞"=cp, sign_change=pm(f(cp-d)) * " → " * pm(f(cp+d)))
    # check endpoint
    if min(abs(f(a)), abs(f(b))) <= max(max(a,b)*eps(), atol)
        return "Sorry, the endpoints must not be zeros for the function"
    end

    zs = find_zeros(f, a, b)
    pts = vcat(a, zs, b)
    for (u,v) ∈ zip(pts[1:end-1], pts[2:end])
        zs′ = find_zeros(x -> 1/f(x), u, v)
        for z′ ∈ zs′
            flag = false
            for z ∈ zs
                if isapprox(z′, z; atol=atol)
                    flag = true
                    break
                end
            end
            !flag && push!(zs, z′)
        end
    end
    if isempty(zs)
	fc = f(a + (b-a)/2)
	return "No sign change, always " * (fc > 0 ? "positive" : iszero(fc) ? "zero" : "negative")
    end

    sort!(zs)
    m,M = extrema(zs)
    d = min((m-a)/2, (b-M)/2)
    if length(zs) > 1
        d′ = minimum(diff(zs))/2
        d = min(d, d′ )
    end
    summarize.([f], zs, d)
end
sign_chart(f, ab::Interval; kwargs...) = sign_chart(f, extrema(ab)...; kwargs...)

"""
    riemann(f, a, b, n; method="right")

Simple Riemann sum, Method is one of "right", "left", "trapezoid", or "simpsons".
"""
function riemann(f::Function, a::Real, b::Real, n::Int; method="right")
    b < a && return -riemann(f, b, a, n; method="right")
    if method == "right"
        meth = (f,l,r) -> f(r) * (r-l)
    elseif method == "left"
        meth= (f,l,r) -> f(l) * (r-l)
    elseif method == "trapezoid"
     meth = (f,l,r) -> (1/2) * (f(l) + f(r)) * (r-l)
    elseif method == "simpsons"
        meth = (f,l,r) -> (1/6) * (f(l) + 4*(f((l+r)/2)) + f(r)) * (r-l)
    end

    xs = range(a, b, length=n+1)
    lrₛ = zip(Iterators.take(xs, n), Iterators.drop(xs, 1))
    sum(meth(f, l, r) for (l,r) in lrₛ)
end

# integration methods for type Interval
riemann(f::Function, ab::Interval, n::Int; method="right") =
    riemann(f, extrema(ab)..., n; method)

QuadGK.quadgk(f::Function, ab::Interval; kwargs...) =
    quadgk(f, extrema(ab)...; kwargs...)
