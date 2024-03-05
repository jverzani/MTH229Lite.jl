## -----
# layout
# plots has plot(p1,p2, ...; layout=(m,n))
# makie has [p1 p2; ...] display layout
# this is in between
function plot(ps::Array{<:Plot, N}; kwargs...) where {N}
    1 <= N <= 2 || throw(ArgumentError("1 or 2 dimensional arrays only"))
    grid_layout(ps; kwargs...)
end


"""
    grid_layout(ps::Array{<:Plot})

Layout an array of plots into a grid. Vectors become rows of plots.

Use `Plot()` to create an empty plot for a given cell.

# Example

```
using DataFrames
n = 25
d = DataFrame(x=sin.(rand(n)), y=rand(n).^2, z = rand(n)) # assume all numeric
nms = names(d)
m = Matrix{Plot}(undef, length(nms), length(nms))

for i ∈ eachindex(nms)
    for j ∈ eachindex(nms)
        if j > i
            p = Plot()
        elseif j == i
            x = d[:,j]
            p = plot(x, type="histogram")
            xlabel!(p, nms[j])  # <<- not working in grid! as differe xaxis purposes
        else
            x = d[:,i]; y = d[:,j]
            p = scatter(x, y)
            xlabel!(p, nms[i]); ylabel!(p, nms[j])
        end
        m[i,j] = p
    end
end
grid_layout(m)
```
"""
function grid_layout(ps::Array{<:Plot};
                     pattern="independent", # or "coupled"
                     legend = false,
                     )
    mn = size(ps)
    if length(mn) == 1
        m, n = (1, only(mn))
    else
        m, n = mn
    end

    layout = Config()
    layout.grid.rows = m
    layout.grid.columns = n
    !isnothing(pattern) && (layout.grid.pattern = pattern)
    !isnothing(legend) && (layout.showlegend = legend)

    data = Config[]
    for (i,p) ∈ enumerate(permutedims(ps))
        xi,yi = "x$i", "y$i"
        for d ∈ p.data
            isempty(d) && continue
            d.xaxis = xi
            d.yaxis = yi
            push!(data, d)
        end
    end

    Plot(data, layout)
end
