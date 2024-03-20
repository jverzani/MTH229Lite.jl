
##
"""
    surface(x, y, z; kwargs...)
    surface!(x, y, z; kwargs...)
    surface(x, y, f::Function; kwargs...)
    surface!(x, y, f::Function; kwargs...)

Create surface plot. Pass `zcontour=true` to add contour plot projected onto the `z` axis.

# Example

```
f(x,y) = 4 - x^2 - y^2
xs = ys = range(-2, 2, length=50)
surface(xs, ys, f)  # zs = f.(xs', ys)
```

## Extended help

From https://discourse.julialang.org/t/3d-surfaces-time-slider/109673
```
z1 = Vector[[8.83, 8.89, 8.81, 8.87, 8.9, 8.87],
                       [8.89, 8.94, 8.85, 8.94, 8.96, 8.92],
                       [8.84, 8.9, 8.82, 8.92, 8.93, 8.91],
                       [8.79, 8.85, 8.79, 8.9, 8.94, 8.92],
                       [8.79, 8.88, 8.81, 8.9, 8.95, 8.92],
                       [8.8, 8.82, 8.78, 8.91, 8.94, 8.92],
                       [8.75, 8.78, 8.77, 8.91, 8.95, 8.92],
                       [8.8, 8.8, 8.77, 8.91, 8.95, 8.94],
                       [8.74, 8.81, 8.76, 8.93, 8.98, 8.99],
                       [8.89, 8.99, 8.92, 9.1, 9.13, 9.11],
                       [8.97, 8.97, 8.91, 9.09, 9.11, 9.11],
                       [9.04, 9.08, 9.05, 9.25, 9.28, 9.27],
                       [9, 9.01, 9, 9.2, 9.23, 9.2],
                       [8.99, 8.99, 8.98, 9.18, 9.2, 9.19],
                       [8.93, 8.97, 8.97, 9.18, 9.2, 9.18]]
xs , ys = 1:length(z1[1]), 1:length(z1) # needed here given interface chosen
surface(xs, ys, z1, colorscale="Viridis")
surface!(xs, ys, map(x -> x .+ 1, z1), colorscale="Viridis", showscale=false, opacity=0.9)
surface!(xs, ys, map(x -> x .- 1, z1), colorscale="Viridis", showscale=false, opacity=0.9)
```

`Julia` users would typically use a matrix to hold the `z` data, but Javascript users would expect a vector of vectors, as above. As `PlotlyLight` just passes on the data to Javascript, the above is perfectly acceptable. Indeed `BinderPlots` converts matrices to this format in such plots.

(The keyword arguments above come from `Plotly`, not `Plots`.)

A parameterized surface can be displayed. Below the `unzip` function returns 3 matrices specifying the surface described by the vector-valued function `r`.

```
r1, r2 = 2, 1/2
r(u,v) = ((r1 + r2*cos(v))*cos(u), (r1 + r2*cos(v))*sin(u), r2*sin(v))
us = vs = range(0, 2pi, length=25)
xs, ys, zs = unzip(us, vs, r)

surface(xs, ys, zs)
```


Plotting a vertical plane poses a slight challenge, as we can't parameterize as `z=f(x,y)`. Here we intersect a surface with the plane `ax + by + 0z = d` and add a trace for the intersection of the two surfaces.

```
f(x, y) = 4 - (x^2 + y^2)

# surface
xs =  ys = range(-2, 2, length=100)
zs = f.(xs', ys)

# (vertical) plane
m, M = extrema(zs)
zzs = range(m, M, length=2)
Xs = ((x,z) -> x).(xs', zzs)
Zs = ((x,z) -> z).(xs', zzs)
a, b, c, d = 1, 1, 0, 1
plane(x,z) = (d - a*x - c*z) / b
Ys = plane.(xs', zzs)

# intersection
g(t) = (d - a*t) / b
γ(t) = (t, y(t), f(t, y(t)))

surface(xs, ys, zs)
surface!(Xs, Ys, Zs, opacity=0.2)
plot!(unzip(γ.(xs))...; linewidth=3)
```
"""
function surface(x, y, z; kwargs...)
    p = _new_plot(; kwargs...)
    surface!(p, x, y, z; kwargs...)
end

surface(x, y, f::Function; kwargs...) =
    surface(x, y, f.(x', y); kwargs...)

surface!(x, y, z; kwargs...) =
    surface!(current_plot[], x, y, z; kwargs...)

surface!(x, y, f::Function; kwargs...) =
    surface!(current_plot[], x, y, f.(x', y); kwargs...)

function surface!(p::Plot, x, y, z;
                  eye = nothing, # (x=1.35, y=1.35, z=..)
                  center = nothing,
                  up = nothing,
                  zcontour = false,
                  aspect_ratio=nothing,
                  kwargs...)

    x, y, z = _adjust_matrix.((x,y,z))
    c = Config(;x,y,z,type="surface")
    _merge!(c; kwargs...)

    # configuration options? colors?
    if zcontour
        c.contours.z = Config(show=true, usecolormap=true,
                              project=Config(;z=true))
    end

    # camera controls
    _camera_position!(p.layout.scene.camera; center, up, eye)

    if !isnothing(aspect_ratio)
        if aspect_ratio == :equal
            p.layout.scene.aspectmode = "data"
            p.layout.scene.aspectratio = Config(x=1, y=1, z=1)
        end
    end

    push!(p.data, c)
    p
end

"""
    wireframe(x, y, z; kwargs...)
    wireframe(x, y, f::Function; kwargs...)
    wireframe!([p::Plot], x, y, z; kwargs...)
    wireframe!([p::Plot], x, y, f::Function; kwargs...)

Create wireframe.

# Example

```
f(x, y) = 4 - x^2 - y^2
xs = ys = range(-2, 2, length=100)
surface(xs, ys, f)
wireframe!(xs, ys, f)
```
"""
function wireframe(x, y, z; kwargs...)
    p = _new_plot(; kwargs...)
    wireframe!(p, x, y, z; kwargs...)
end

wireframe(x, y, f::Function; kwargs...) =
    wireframe(x, y, f.(x', y); kwargs...)

wireframe!(x, y, z; kwargs...) =
    wireframe!(current_plot[], x, y, z; kwargs...)

wireframe!(x, y, f::Function; kwargs...) =
    wireframe!(current_plot[], x, y, f.(x', y); kwargs...)

function wireframe!(p::Plot, x, y, z; kwargs...)
    surface!(p, x, y, z; kwargs...)
    # surface plot with modifications
    d = p.data[end]
    d.hidesurface = true
    d.contours.x.show = true
    d.contours.y.show = true

    p
end
