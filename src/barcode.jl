"""
    PersistencePair{T, U}

fields:

* `birth::T`
* `death::T`
* `data::U`
"""
struct PersistencePair{T, U}
    birth ::T
    death ::T
    data  ::U
end

function PersistencePair(birth, death, data::U=nothing) where U
    b, d = promote(birth, death)
    T    = typeof(b)
    PersistencePair{T, U}(b, d, data)
end

function Base.show(io::IO, pair::PersistencePair{T, U}) where {T, U}
    compact = get(io, :compact, false)
    if !compact
        print(io, "PersistencePair{$T, $U}")
    end
    print(io, "($(birth(pair)), $(death(pair))")
    if U != Void
        print(io, "; ")
        showcompact(io, data(pair))
    end
    print(io, ")")
end

"""
    birth(pair)

Get the birth time of a `PersistencePair`.
"""
birth(pair::PersistencePair) = pair.birth
"""
    death(pair)

Get the death time of a `PersistencePair`.
"""
death(pair::PersistencePair) = pair.death
"""
    data(pair)

Get the data associated with a `PersistencePair`.
"""
data(pair::PersistencePair) = pair.data

Base.start(pair::PersistencePair) = 1
Base.next(pair::PersistencePair, i::Int) =
    if i == 1
        (birth(pair), 2)
    else
        (death(pair), 3)
    end
Base.done(pair::PersistencePair, i::Int) = i == 3

# ============================================================================ #
"""
    PersistenceBarcode{T, U, D, A<:AbstractVector{PersistencePair{T, U}}}

fields:

* `barcodes::SVector{D, A}`

The `barcodes` contains a vector of `PersistencePair`s for each dimension.

constructors:

`PersistenceBarcode(arr::AbstractVector{A})`
`PersistenceBarcode(arrs::Vararg{A})`
"""
struct PersistenceBarcode{T, U, D, A<:AbstractVector{PersistencePair{T, U}}}
    barcodes::SVector{D, A}
end

function PersistenceBarcode(arr::AbstractVector{A}) where
        A<:AbstractVector{PersistencePair{T, U}} where {T, U}
    D = length(arr)
    PersistenceBarcode{T, U, D, A}(SVector{D}(arr))
end

function PersistenceBarcode(arrs::Vararg{A, D}) where
        {A<:AbstractVector{PersistencePair{T, U}}, D} where {T, U}
    PersistenceBarcode{T, U, D, A}(SVector{D}([arrs...]))
end

function Base.show(io::IO, barcode::PersistenceBarcode{T, U, D}) where {T, U, D}
    compact = get(io, :compact, false)
    if compact
        print(io, "$(D-1)-d PersistenceBarcode{$T, $U}")
    else
        print(io, "$(D-1)-d PersistenceBarcode{$T, $U}:")
        for i in 0:D-1
            print(io, "\n dim $i:")
            for p in barcode[i]
                print(io, "\n  ")
                showcompact(io, p)
            end
        end
    end
end

function Base.:(==)(barcode1::PersistenceBarcode, barcode2::PersistenceBarcode)
    dim(barcode1) == dim(barcode2) || return false
    for i in eachindex(barcode1)
        barcode1[i] == barcode2[i] || return false
    end
    true
end

"""
    dim(barcode)

Get the dimension of a `PersistenceBarcode`.
"""
dim(::PersistenceBarcode{T, U, D}) where {T, U, D} = D - 1

# Indexing (zero-based!)
Base.getindex(barcode::PersistenceBarcode, i) = barcode.barcodes[i + 1]
Base.length(barcode::PersistenceBarcode{T, U, D}) where {T, U, D} = D
Base.endof(barcode::PersistenceBarcode) = endof(barcode.barcodes) - 1
Base.eachindex(barcode::PersistenceBarcode) = 0:dim(barcode)

# Iteration
Base.start(barcode::PersistenceBarcode) = start(barcode.barcodes)
Base.next(barcode::PersistenceBarcode, st) = next(barcode.barcodes, st)
Base.done(barcode::PersistenceBarcode, st) = done(barcode.barcodes, st)
Base.iteratorsize(::PersistenceBarcode) = Base.HasLength()
Base.iteratoreltype(barcode::PersistenceBarcode) = Base.HasEltype()
Base.eltype(barcode::PersistenceBarcode{T, U, D, A}) where {T, U, D, A} = A

Base.filter(f, barcode::PersistenceBarcode) =
    PersistenceBarcode(map(b -> filter(f, b), barcode.barcodes))

Base.map(f, barcode::PersistenceBarcode) =
    PersistenceBarcode(map(b -> map(f, b), barcode.barcodes))
