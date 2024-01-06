
const e = exp(1)

# f'
Base.adjoint(f::Function) = x -> ForwardDiff.derivative(f, float(x))


# simple functions
tangent(f, c) = x -> f(c) + f'(c)*(x-c)
secant(f, a, b) = x -> f(a) + (f(b)-f(a)) / (b-a) * (x - a)
fisheye(f)=x->atan(f(tan(x)))
newton(f, x; kwargs...) = find_zero((f, f'), x, Roots.Newton(); kwargs...)
rangeclamp(f, hi=20, lo=-hi; replacement=NaN) = x -> lo < f(x) < hi ? f(x) : replacement

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

#
function sign_chart(f, a, b; atol=1e-6)
    pm(x) = x < 0 ? "-" : x > 0 ? "+" : "0"
    summarize(f,cp,d) = (DNE_0_∞=cp, sign_change=pm(f(cp-d)) * " → " * pm(f(cp+d)))
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


function riemann(f::Function, a::Real, b::Real, n::Int; method="right")
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
