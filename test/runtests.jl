using MTH229Lite
using Test

@testset "MTH229Lite.jl" begin

    f(x) = x^5 - x - 1

    lim(f, 1)
    lim(f, 1, dir="-")

    @test bisection(f, 1, 2) ≈ 1.1673039782614187
    @test newton(f, 1) ≈ 1.1673039782614187
    @test fzeros(f, 1, 2) ≈ [1.1673039782614187]

    sign_chart(f, 1, 2)

    r = riemann(f, 1, 2, 1000)
    q, err = quadgk(f, 1, 2)
    @test abs(r - q) <= 1/10
    @test iszero(err) # polynomial

    plot(f, 0, 1);

    # test symbolic
    @symbolic x
    u = sin(x)
    eq = sin(x) ~ cos(x)
    a, b = 0, 2pi
    I = a..b

    # test these work
    lim(u, a)
    sign_chart(u, a, b)
    sign_chart(u, I)
    riemann(u, a, b, 1000)
    riemann(u, I, 1000)
    quadgk(u, a, b)
    quadgk(u, I)

    # numeric solve
    ips = solve(eq, I)
    @test sin.(ips) ≈ cos.(ips)
    @test solve(eq, a) ≈ first(ips)
    @test solve(eq, a) ≈ newton(sin(x) - cos(x), a) # no Equation interface for newton
end

@testset "plots" begin
    @symbolic x
    u = sin(x)
    eq = sin(x) ~ cos(x)
    a, b = 0, 2pi
    I = a..b

    # plots
    p₁ = plot(u, a, b)
    p₂ = plot(u, I)
    p₃ = plot(eq, a, b)
    p₄ = plot(eq, I)
    p₅ = scatter([1,2, NaN,4], [1,NaN, 3,4])
    grid_layout([p₁ p₂ p₃; p₄ p₅ Plot()], legend=false)

    p = plot(u, a, b)
    xlims!(p, (1,2))
    ylims!(p, (0, 1))
    title!(p, "plot of u")
    annotate!(p, ((3/2, 1/2, "A"),), pointsize=20)

    nothing

end
@testset "symbolic solve" begin
    @symbolic x p

    eqn = x + 3 ~ 4
    @test solve(eqn).rhs() ≈ 1
    @test isa(solve(eqn).lhs(), SimpleExpressions.Symbolic)

    m,b = p[1], p[2]
    @test solve(m*x + b ~ -40).rhs(:, (9/5, 32)) == -40

    eqn = 3x + 7 ~ 2x + 8
    u = solve(eqn)
    @test eqn.lhs(u.rhs()) == eqn.rhs(u.rhs())

    eqn = sin(x) ~ 1//2
    @test solve(eqn).rhs() ≈ asin(1//2)

    eqn = exp(exp(x)) ~ 10
    @test solve(eqn).rhs() ≈ log(log(10))

    eqn = log(x) ~ p
    solve(eqn).rhs(:, 2) ≈ exp(2)

    # polynomials of degree 2 or more are different; they return vectors
    eqn = x^2 - x ~ 1
    a,b = solve(eqn)
    @test a() == (1 + sqrt(5))/2
    @test b() == (1 - sqrt(5))/2

    # quadratics may have parameters
    eqn = x^2 - x ~ p
    a,b = solve(eqn)
    @test a(:,1) == (1 + sqrt(5))/2

    # higher order are just numbers
    us = solve(x^5 - x ~ 1)
    @test only(filter(isreal, us)) ≈ 1.16730397826

    # fails, can be silent or error
    eqn = sin(x) ~ cos(x)
    @test !isa(solve(eqn).lhs(), SimpleExpressions.Symbolic)

    eqn = sin(x) ~ 2
    @test_throws DomainError solve(eqn).rhs()

end
