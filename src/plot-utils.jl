unzip(vs) = Tuple([vs[j][i] for j in eachindex(vs)] for i in eachindex(vs[1]))
#unzip(v,vs...) = unzip([v, vs...])
unzip(r::Function, a, b, n) = unzip(r.(range(a, stop=b, length=n)))
# return (xs, f.(xs)) or (f₁(xs), f₂(xs), ...)
function unzip(f::Function, a, b)
    n = length(f(a))
    if n == 1
        return PlotUtils.adapted_grid(f, (a,b))
    else
        xsys = [PlotUtils.adapted_grid(x->f(x)[i], (a,b)) for i ∈ 1:n]
        xs = sort(vcat([xsys[i][1] for i ∈ 1:n]...))
        return unzip(f.(xs))
    end

end


    ## plotif
    function identify_colors(g, xs, colors=(:red, :blue, :black))
        F = (a,b) -> begin
            ga,gb=g(a),g(b)
            ga * gb < 0 && return nothing
            ga >= 0 && return true
            return false
        end
        find_colors(F, xs, colors)
    end

    # F(a,b) returns true, false, or nothing
    function find_colors(F, xs, colors=(:red, :blue, :black))
        n = length(xs)
        cols = repeat([colors[1]], n)
        for i in 1:n-1
            a,b = xs[i], xs[i+1]
            val = F(a,b)
            if val == nothing
                cols[i] = colors[3]
            elseif val
                cols[i] = colors[1]
            else
                cols[i] = colors[2]
            end
        end
        cols[end] = cols[end-1]
        cols
    end


    function rle(v::Vector{T}) where {T} # stats base
        n = length(v)
        vals = T[]
        lens = Int[]

        n>0 || return (vals,lens)

        cv = v[1]
        cl = 1

        i = 2
        @inbounds while i <= n
            vi = v[i]
            if vi == cv
                cl += 1
            else
                push!(vals, cv)
                push!(lens, cl)
                cv = vi
                cl = 1
            end
            i += 1
        end

        # the last section
        push!(vals, cv)
        push!(lens, cl)

        return (vals, lens)
    end
