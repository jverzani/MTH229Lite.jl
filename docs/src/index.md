```@meta
CurrentModule = MTH229Lite
```

# MTH229Lite

Documentation for [MTH229Lite](https://github.com/jverzani/MTH229Lite.jl).

This package provides helpers for learning Calculus I using the `Julia` programming language. `MTH229Lite` is a lighter-weight alternative to `MTH229`  (or `CalculusWithJulia`). Doing tasks from a first semester calculus class with the `MTH229` package is well illustrated at [mth229.github.io](https://mth229.github.io). Much more of the same is shown at [calculuswithjulia.github.io](https://calculuswithjulia.github.io).


# Installation

There is a binder [notebook](https://mybinder.org/v2/gh/mth229/229-projects/lite?labpath=blank-notebook.ipynb) available for use over the internet. Otherwise, the package is not registered, so is installed as follows:

```julia
import Pkg
Pkg.add(url="https://github.com/jverzani/MTH229Lite.jl")
```


# Usage

Once installed, each session the package must be loaded, for example,  through the `using` command:

```@example lite
using MTH229Lite
using PlotlyDocumenter # hide
```

Like the `MTH229` package, this pulls in various helper functions and also loads several useful packages, such as `Roots`, `QuadGK`, `ForwardDiff`, and `SpecialFunctions`.

## Differences from the MTH229 package

`MTH229` also loads the `SymPy` package for symbolic math and anticipates the use of `Plots`.

The [`PlotlyLightLite`](https://jverzani.github.io/PlotlyLightLite.jl/dev/) package is  loaded by `MTH229Lite`,  a lite version of a `Plots.jl` utilizing the small but powerful `PlotlyLight` package.

The symbolic math package `SymPy` is not loaded, as it is with the `MTH229` package. The `SimpleExpressions` package is provided, which has support for making symbolic expressions. It is very limited, but can still be useful.

## Functions and expressions

There is no additional support for Base `Julia` as regards the defining of functions.

However, the [`SimpleExpressions`](https://jverzani.github.io/SimpleExpressions.jl/dev/) package allows an alternative for defining basic mathematical functions using expressions involving a symbolic value (and possible parameter). The following illustrates:

```@example lite
f(x) =  sin(x) + cos(2x)

@symbolic x p
u = sin(x) + cos(2x)
u(1), f(1)
```

The object `u` is quite different from `f`, a function, in that it is a symbolic expression that can be subsequently manipulated. For examples, functions can't simply be added or squared, but expressions can be.
An expression, like `u`, has its "call" method overloaded so that `u(1)` substitutes in for `x`. When a parameter is used (the `p` in the `@symbolic` call above) one can call `u(x,p)` to substitute in for both `x` and `p`; `u(x)` to substitute in for `x` (leaving `p`), or `u(:,p)` to substitute in for just `p` (leaving `x`).

A symbolic expression can be used in place of a function for higher order functions, such as `plot`, `lim`, `riemann`, etc.


## Plotting

As mentioned, this package avoids using `Plots.jl` for plotting, as that package can be resource intensive. This package uses a light-weight alternative which utilizes basically the same interface for the basic graphics of calculus. It is provided by `PlotlyLightLite`, a bare-bones package leveraging the powerful `PlotlyLight` package.

The simplest means to plot a function `f` over the interval `[a,b]` is the pattern `plot(f, a, b)`. For example:

```@example lite
plot(sin, 0, 2pi)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

The `sin` object refers to a the underlying function to compute sine. More commonly, the function is user-defined as `f`, or some such, and that function object is plotted.


This package can use symbolic expressions to specify functions and provides an interface to specify intervals with `..`. To illustrate, we have:

```@example lite
u = exp(-x) * (sin(5x) + sin(101x))
I = -1..2  # prints as ⟦-1, 2⟧
plot(u, I)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

Layers can be added to a basic plot. The notation follows `Plots.jl` and uses `Julia`'s convention of indicating functions which mutate their arguments with a `!`. The underlying plot is mutated (by adding a layer) and reference to this may or may not be in the `plot!` call. (When missing, the current plotting figure, determined by `current()`, is used.)

```@example lite
@symbolic x
I = 0..2pi
plot(sin(x), I)

plot!(cos(x))    # no limits needed, as they are computed from the current figure

J = 0..pi/2
plot!(x, J)      # limits can be specified
plot!(1 - x^2/2, J)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

Symbolic equations have both the left and right-hand sides plotted:

```@example lite
@symbolic x
plot(cos(x) ~ 2x, 0..2pi)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```


## Limits

The `MTH229` package provides `lim` to illustrate limits *numerically*, as does `MTH229Lite`. For example, this makes a table of values illustrating how the (right) limit of ``f(x) = (\cos(x) - 1)/x^2`` at ``0`` is ``-1/2``:

```@example lite
lim((cos(x) - 1)/x^2, 0)
```

(It also hints at the numeric instability possible with this approach.)

While graphical approaches to limits are also possible, the `limit` function of `SymPy` is not provided.


## Derivatives

The `ForwardDiff` package is one of many for `Julia` for computing automatic derivatives. These have the advantage of being as exact as a symbolic derivative, but generally much faster to compute. The `MTH229Lite` package also overrides the `'` operator to take the derivative of a function using `ForwardDiff.derivative`:

```@example lite
f(x) = exp(-x)*sin(x)
f'(2)
```

The object `f'` can be plotted or passed along to other methods expecting a function object.

The `SimpleExpressions` package also can take derivatives of the symbolic expressions. The `'` notation is extended to expressions:

```@example lite
@symbolic x
u = exp(-x)*sin(x)
u'
```

Unlike `SymPy`, symbolic expressions of `SimpleExpressions` are **not** simplified, so can get overwhelming. They too can be passed into other methods where a function is expected.

The `D` function will take a symbolic derivative of a function, as with `D(sin)`.

!!! note "differences"
    In `SymPy` the `diff` function takes derivatives. The `diff` function is more general. In `SimpleExpressions`, the variable `x` is treated as a scalar for purposes of differentiation and is not specified. Differentiation works by overloading several common mathematical functions. If differentiation encounters a function for which an overload is not defined, an error will be thrown.

!!! note "Type piracy"
    The use of `'` to find derivatives of functions is considered to be type piracy. Neither the type `Function` or the notation `'` is defined by this package. Type piracy is frowned on heavily, as it can quietly change behaviour in other packages when loaded. In this example, if `MTH229Lite` is loaded, an array of functions would not have the typical notion of "`'`" available. The `'` notation is pedagogically useful, but a recommended way to find the derivative of `f` at `x` is through `ForwardDiff.derivative(f, x)`.



## Zero finding

As illustrated at [mth229.github.io](https://mth229.github.io), an equation ``f(x)=0`` can be solved *numerically* by a few methods:

* The *bisection* method. For a continuous function, `f`, this method guarantees a solution within a **bracketing** interval `[a,b]`.
* *Newton's* method. This rapidly solves the equation from an *initial* guess, provided the function is well behaved and the guess is a good one.

(There are many more methods, of course, zero finding by the secant method being one of the oldest known mathematical algorithms.)

This package, like `MTH229`, also provides the functions `bisection` and `newton` for carrying out these two algorithms.

To solve ``f(x) = g(x)``, an auxiliary function ``h(x) = f(x)-g(x)`` is used.

More generally, the `Roots` package provides `find_zero` as an interface to several methods. (The `fzero` function is an alias).

* `find_zero(f, (a,b))` -- for `(a,b)` a **bracketing** interval -- will call a more robust variant of the bisection method.
* `find_zero(f, a)` -- for an initial guess `a` -- will call a method similar to Newton's method (a hybrid secant method).

The `find_zeros(f, a, b)` function call scans over the interval `[a,b]` and numerically attempts to identify all zeros of `f`; `fzeros` is an alias.

When a function is *not* continuous, such as $f(x) = 1/x$ at $0$, these bracketing methods may return values where the function has a *sign* change, though not a zero:

```@example lite
find_zero(1/x, (-1, 1))
```

Solving ``f(x) = g(x)`` is done by solving the related function `h(x) = f(x) - g(x) = 0`.

### Symbolic equations

The `SimpleExpressions` package provides a  means to specify a symbolic equation with the `~` operator  (`=` is assignment, `==` is for relaxed comparison (e.g. ignoring type), `===` is for identical testing). This notation is used by `SymPy` and was borrowed from `Symbolics`.

The `plot` generic has a method for symbolic equations which plots *both* functions over the interval.

The  `solve` generic has these variants for such symbolic equations

* `solve(eqn, a)` uses the hybrid secant method starting at a
* `solve(eqn, (a,b))` uses a bisection method for a bracketing interval
* `solve(eqn, I)`, **where** `I` is an interval, uses `find_zeros` to scan for all zeros.
* `solve(eqn)` attempts to solve the symbolic equation by applying inverse functions. It can also solve polynomials using their roots.

This example illustrates using `scatter!` to add a few points (see the more on plotting section):

```@example lite
@symbolic x
I = 0..2pi
eqn = sin(x) ~ cos(x)

plot(eqn, I; legend=false)
ips = solve(eqn, I) # all solutions in I
scatter!(ips, sin.(ips), markersize=10)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

Here is an example that illustrates the mean value theorem and the helper functions `secant(f, a, b)` and `tangent(f, c)`.

```@example lite
@symbolic x
u = (x-1)*(x-2)*(x-3)
a, b = 0.5, 3.6

plot(u, a..b; legend=false, linewidth=5)
plot!(secant(u, a, b))    # or plot!(u(a) + (u(b)-u(a))/(b-a)*(x-a))
ms = solve(u' ~ (u(b)-u(a))/(b-a), a..b)
for m in ms
    plot!(tangent(u, m))  # or plot!(u(m) + u'(m)*(x-m))
end
scatter!(ms, u.(ms), markersize=10)
title!("Mean value theorem illustration")

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

Of course, using `tangent` and `secant` can be bypassed, as noted in the comments.

## First and second derivatives

There is some support for working with first and second derivatives, similar to that provided in the `MTH229` package.

The `plotif(f, g, a, b)` function is provided to explore the graph of `f` depending on sign of `g`.

```@example lite
@symbolic x
I = -2..1
u = exp(-x) * (sin(x) + sin(3x) + sin(5x))
p = plotif(u, u'', I) # show concave up

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

The `sign_chart` function shows sign changes, in this case of the derivative:

```@example lite
sign_chart(u', I)
```

### Example

A box with square base is to be constructed from 108 inches of material. What dimensions produce the greatest volume?

This is a classic optimization problem which is solvable using techniques for a continuous scalar function over a closed interval. To get there, we identify the constraint: ``S = 108 = 2a^2 + 4\cdot a \cdot h``. The function to maximize is ``V= a \cdot a \cdot h``

We show how to solve this using functions

```@example lite
h(a) = (108 - 2a^2)/(4a) # solve the constraint for h
V(a) = a^2 * h(a)
```

Now, `a` can't be negative, and can't be bigger than ``\sqrt{108/2}``:

```@example lite
I = 0..sqrt(108/2)
plot(V, I)

delete!(current().layout, :width)  # hide
delete!(current().layout, :height) # hide
to_documenter(current())           # hide
```

The answer is near `4`:

```@example lite
a = find_zero(V', 4)
```

Though a graph suffices, we can see from the first derivative test that we have a local maximum:

```@example lite
sign_chart(V', I) # from + -> -
```

Using the second derivative test might be done with

```@example lite
cps = find_zeros(V', I)
[cps V''.(cps)]  # V''  is - at 6.0, a critical point, so at a local maximum
```

----

To solve this symbolically is possible, but requires a sleight of hand as to solve for `h` we make it symbolic and use `a` as a parameter:

```@example lite
@symbolic ℎ 𝑎         # sleight of hand here where 𝑎 is Symbolic, 𝑎 parameter
constraint = 108 ~ 2𝑎^2 + 4𝑎*ℎ
soln = solve(constraint)
```

Then `𝑎` is made symbolic and substituted in for `𝑎` which allows us to proceed:

```@example lite
@symbolic 𝑎
ℎ = soln.rhs(:,𝑎)     # then substitute in 𝑎 for 𝑎
𝑉 = 𝑎 * 𝑎 * ℎ
I = 0..sqrt(108/2)
plot(𝑉, I)            # near 4
𝑎₀ = solve(𝑉' ~ 0, 4)
𝑎₀, ℎ(𝑎₀), 𝑉(𝑎₀)      # a cube: 𝑎₀ ≈ 𝑎(𝑎₀)
```

!!! note "`𝑎`, `ℎ`, `𝑉`?"
    The symbols `h` and `V` were assigned to generic functions earlier and hence can't be repurposed as a variable, even a symbolic one. Unicode variants are used instead (e.g., `\ith[tab]`). While `Julia` is a dynamic language with the ability to change the type of value a variable name refers to, it keeps a separate table for generic functions and these names can't serve as variable names once added and vice versa.

## Integrals

As with `MTH229`, a `riemann` function is provided for approximating definite integrals with  simple `Riemann` sums along with the trapezoid and Simpson's methods. The `quadgk` function from the `QuadGK` package is also imported for a more accurate and performant alternative. The `integrate` function from `SymPy` is not available -- only numeric integrals are.

For example, consider a volume of revolution for a simple [pint glass](https://www.dimensions.com/element/american-pint-glass). Rounding, we have a height of ``15``cm, a width at the top of ``8``cm and at the bottom of ``6``cm. Viewed mathematically, it is volume of revolution of the function ``r(h)=3 + (4-3)/(15-0)\cdot h``. This doesn't account for the thickness of the walls or the base, which can vary to give more heft at the cost of volume.

We can answer a few questions:

* How much does this theoretical glass hold, in ml?
* How high to fill for ``16``oz (``473``ml)?
* How high to fill for  ``8``oz?

We will use `quadgk`. As that function returns a tuple of values -- the answer and an error estimate -- and we only want the first, we use `first` below:

```@example lite
r(h) = 3 + (4-3)/(15-0) * h # ⚠ not 3 + 1/15h!
dv(h) = pi * r(h)^2
V(b) = first(quadgk(dv, 0, b))
V(15)
```

This is more than ``473``, as we didn't account for the glass thickness, as noted above.

To find the height to get ``473`` we use `find_zero`, showing off how we can use a parameter:

```@example lite
h(b, p) = V(b) - p
find_zero(h, (0, 15), p = 473)
```

And to fill half that, we get

```@example lite
find_zero(h, (0, 15), p = 473/2)
```

This value is greater than half the height to fill to ``473``, a typical situation with drinking glasses.

----

As an aside, to do this "symbolically" is a bit awkward, as we might want both the function passed to `quadgk` and the limit of integration to be *different* symbolic values. But `SimpleExpressions` is really simple -- just one at a time. Here we use that to be the limit of integration.

```@example lite
@symbolic b p
r(h) = 3 + (4-3)/(15-0) * h # ⚠ not 3 + 1/15h!
dv(h) = pi * r(h)^2
Vb = first(SimpleExpressions.@symbolic_expression quadgk(dv, 0, b))
solve(Vb ~ p, (0, 15), p = 473), solve(Vb ~ p, (0, 15), p = 473/2)
```

!!! note "`@symbolic_expression`"
    The `quadgk` function is not registered to work with symbolic values, like `b` above. Just evaluating `quadgk(dv, 0, b)` will error. The non-exported macro `@symbolic_expression` creates a symbolic expression -- a deferred function evaluation --  from a function call. This allows the expression to be used as a function, such as is done in the last line above.
