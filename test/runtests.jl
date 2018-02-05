    using PersistenceBarcodes
using Base.Test
using Plots; plotly()
using Suppressor

@testset "PersistenceBarcodes" begin
    @testset "PersistencePair" begin
        # Types
        pair1 = PersistencePair(0, 2)
        @test pair1 isa PersistencePair{Int, Void}
        pair2 = PersistencePair(0, Inf, [1])
        @test pair2 isa PersistencePair{Float64, Vector{Int}}

        # Getters
        @test birth(pair1) ≡ 0
        @test birth(pair2) ≡ 0.0
        @test death(pair1) ≡ 2
        @test death(pair2) ≡ Inf
        @test data(pair1)  ≡ nothing
        @test data(pair2) == [1]

        # Deconstruction
        b1, d1 = pair1
        @test b1 ≡ 0 && d1 ≡ 2
        b2, d2 = pair2
        @test b2 ≡ 0.0 && d2 ≡ Inf

        # Show
        @test @capture_out(print(pair1)) ==
            "PersistencePair{$Int, Void}(0, 2)"
        @test @capture_out(print(pair2)) ==
            "PersistencePair{Float64, Array{$Int,1}}(0.0, Inf; [1])"
        @test @capture_out(showcompact(pair1)) == "(0, 2)"
        @test @capture_out(showcompact(pair2)) == "(0.0, Inf; [1])"

        # Make sure the correct IO is used.
        @test @capture_err(print(STDERR, pair1)) ==
            "PersistencePair{$Int, Void}(0, 2)"
        @test @capture_err(print(STDERR, pair2)) ==
            "PersistencePair{Float64, Array{$Int,1}}(0.0, Inf; [1])"
        @test @capture_err(showcompact(STDERR, pair1)) == "(0, 2)"
        @test @capture_err(showcompact(STDERR, pair2)) == "(0.0, Inf; [1])"
    end

    @testset "PersistenceBarcode" begin
        # Construction
        barcode1 = PersistenceBarcode(PersistencePair.(Float64[0,0,0], [1,2,3], [1,2,3]))
        barcode2 = PersistenceBarcode([PersistencePair.(Float64[0,0,0], [1,2,3]),
                                       PersistencePair.(Float64[1,0],   [Inf,2])])
        barcode3 = PersistenceBarcode(PersistencePair.(Float64[0,0,0], [1,2,3]),
                                      PersistencePair.(Float64[1,0],   [Inf,2]))
        @test barcode2 == barcode3
        @test barcode1 isa PersistenceBarcode{Float64, Int}
        @test barcode2 isa PersistenceBarcode{Float64, Void}

        @test dim(barcode1) == 0
        @test dim(barcode2) == 1

        # Indexing
        @test barcode1[0] == PersistencePair.([0.0,0.0,0.0], [1.0,2.0,3.0], [1,2,3])
        @test barcode2[1] == PersistencePair.([1.0,0.0], [Inf,2.0])

        # Show
        bc1_str =
            """
        0-d PersistenceBarcode{Float64, $Int}:
         dim 0:
          (0.0, 1.0; 1)
          (0.0, 2.0; 2)
          (0.0, 3.0; 3)
        """
        @test @capture_out(println(barcode1)) == bc1_str
        @test @capture_err(println(STDERR, barcode1)) == bc1_str
        @test @capture_out(showcompact(barcode1)) ==
            "0-d PersistenceBarcode{Float64, $Int}"
        @test @capture_err(showcompact(STDERR, barcode1)) ==
            "0-d PersistenceBarcode{Float64, $Int}"

        bc2_str =
            """
        1-d PersistenceBarcode{Float64, Void}:
         dim 0:
          (0.0, 1.0)
          (0.0, 2.0)
          (0.0, 3.0)
         dim 1:
          (1.0, Inf)
          (0.0, 2.0)
        """
        @test @capture_out(println(barcode2)) == bc2_str
        @test @capture_err(println(STDERR, barcode2)) == bc2_str
        @test @capture_out(showcompact(barcode2)) ==
            "1-d PersistenceBarcode{Float64, Void}"
        @test @capture_err(showcompact(STDERR, barcode2)) ==
            "1-d PersistenceBarcode{Float64, Void}"

        # Iteration
        l = Int[]
        T = eltype(barcode2)
        for p in barcode2
            push!(l, length(p))
            @test p isa T
        end
        @test l == [3, 2]

        l = map(length, collect(barcode2))
        @test l == [3, 2]

        @test filter(p -> !isfinite(death(p)), barcode2) ==
            PersistenceBarcode(PersistencePair{Float64, Void}[],
                               [PersistencePair(1.0, Inf)])

        @test map(p -> PersistencePair(death(p),0), barcode2) ==
            PersistenceBarcode(PersistencePair.([1.0,2.0,3.0],[0,0,0]),
                               PersistencePair.([Inf,2.0], [0,0]))


        # map, filter
    end

    @testset "plot" begin
        barcode = PersistenceBarcode(PersistencePair.(Float64[0,0,0], [1,2,3]),
                                     PersistencePair.(Float64[1,0],   [Inf,2]))

        @test PersistenceBarcodes.getlastdeath(barcode, 0:1) ≡ 3.0
        @test PersistenceBarcodes.getlastdeath(barcode, 0)   ≡ 3.0
        @test PersistenceBarcodes.getlastdeath(barcode, 1)   ≡ 2.0

        # Barcode plot
        @test plot(barcode)                ≠ nothing
        @test plot(barcode, dims = 0:1)    ≠ nothing
        @test plot(barcode, dims = 1)      ≠ nothing
        @test plot(barcode, dims = 0)      ≠ nothing
        @test plot(barcode, dims = [1, 0]) ≠ nothing

        @test_throws ArgumentError plot(barcode, dims = [1, 0, -1])
        @test_throws ArgumentError plot(barcode, dims = [0, 2])
        @test_throws ArgumentError plot(barcode, dims = 2)
        @test_throws ArgumentError plot(barcode, dims = -1)

        # Diagram plot
        @test persistencediagram(barcode)                ≠ nothing
        @test persistencediagram(barcode, dims = 0:1)    ≠ nothing
        @test persistencediagram(barcode, dims = 1)      ≠ nothing
        @test persistencediagram(barcode, dims = 0)      ≠ nothing
        @test persistencediagram(barcode, dims = [1, 0]) ≠ nothing

        @test_throws ArgumentError persistencediagram(barcode, dims = [1, 0, -1])
        @test_throws ArgumentError persistencediagram(barcode, dims = [0, 2])
        @test_throws ArgumentError persistencediagram(barcode, dims = 2)
        @test_throws ArgumentError persistencediagram(barcode, dims = -1)
        @test_throws ArgumentError persistencediagram(barcode, [1,2,3])
        @test_throws ArgumentError persistencediagram([1,2,3])
    end
end
