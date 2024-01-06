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

    plot(f, 0, 1)
end
