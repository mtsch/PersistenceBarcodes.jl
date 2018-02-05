function getlastdeath(barcode::PersistenceBarcode{T}, dims) where T
    lastdeath = typemin(T)
    for i in dims
        lastdeath = max(lastdeath,
                        maximum(map(barcode[i]) do p
                                d = death(p)
                                isfinite(d) ? d : typemin(T)
                                end))
    end
    lastdeath
end

function checkdims(barcode::PersistenceBarcode, dims)
    dims == nothing           && return 0:dim(barcode)
    any(dims .< 0)            && throw(ArgumentError("Invalid `dims`!"))
    any(dims .> dim(barcode)) && throw(ArgumentError("Invalid `dims`!"))
    dims
end

@recipe function f(barcode::PersistenceBarcode{T};
                   dims = nothing, infinity = nothing) where T
    #TODO: Clean this part up?
    _dims = checkdims(barcode, dims)
    lastdeath = getlastdeath(barcode, _dims)
    if infinity == nothing
        infty = round(lastdeath, RoundUp) +
            (lastdeath > 1 ? length(digits(round(Int, lastdeath))) : 0)
    else
        infty = infinity
    end

    padding = lastdeath * 0.1
    xlim --> [0, infty + padding]
    h = 1
    for dim in _dims
        @series begin
            seriestype := :path
            label := "dim = $dim"
            linewidth --> 3
            marker --> 1

            xs = T[]; ys = T[]
            for (bth, dth) in barcode[dim]
                dth = isfinite(dth) ? dth : infty
                append!(xs, [bth, dth, NaN])
                append!(ys, [h,   h,   NaN])
                h += 1
            end
            xs, ys
        end
    end
    ylim --> [0, h+1]

    @series begin
        seriestype := :path
        label := "infinity"
        color := :grey
        [infty, infty], [0, h+1]
    end
end

@userplot PersistenceDiagram
@recipe function f(pd::PersistenceDiagram; dims=nothing, infinity=nothing)
    if length(pd.args) ≠ 1 || !(typeof(first(pd.args)) <: PersistenceBarcode)
        throw(ArgumentError("barcode is expecting a single PersistenceBarcode" *
                            " argument. Got: $(typeof(pd.args))"))
    end
    #TODO: Clean this part up?
    barcode = pd.args[1]
    _dims = checkdims(barcode, dims)
    lastdeath = getlastdeath(barcode, _dims)
    if infinity == nothing
        infty = round(lastdeath, RoundUp) +
            (lastdeath > 1 ? length(digits(round(Int, lastdeath))) : 0)
    else
        infty = infinity
    end
    padding = lastdeath * 0.1

    xlims --> (-padding, lastdeath)
    ylims --> (-padding, infty + padding)

    xlabel := "birth"
    ylabel := "death"

    # Births and deaths.
    for dim in _dims
        @series begin
            seriestype := :scatter
            label := "dim = $dim"

            xs = map(birth, barcode[dim])
            ys = map(death, barcode[dim])
            map!(y -> isfinite(y) ? y : infty, ys, ys)
            xs, ys
        end
    end
    # x = y line
    @series begin
        seriestype := :path
        label := ""
        color := :black
        [-padding, infty], [-padding, infty]
    end
    # infinity
    @series begin
        seriestype := :path
        label := "infinity"
        color := :grey
        [-padding, infty], [infty, infty]
    end
end
