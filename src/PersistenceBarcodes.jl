module PersistenceBarcodes

using StaticArrays
using RecipesBase

include("barcode.jl")
include("plotting.jl")

export
    PersistencePair, birth, death, data,
    PersistenceBarcode, dim, barcodes,
    persistencediagram, persistencediagram!

end
