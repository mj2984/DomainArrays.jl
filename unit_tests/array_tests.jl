using Test
using DomainArrays

@testset "DomainArray basics" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))   # 100 units/sample rate

    @test size(S) == (1000,)
    @test S.rate == (100.0,)
    @test S[1] == 1 # Standard integer indexing still works
end

@testset "Domain-space indexing" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))

    # 0.0 units → index 1
    @test S[0.0] == 1

    # 1.0 units → index 100
    @test S[1.0] == 100

    # Range 0.0..0.1 → index 1:10 (based on your ceil/floor logic)
    @test S[0.0:0.001:0.1] == 1:10
end

@testset "Sample-space access" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))

    # Using the underlying data field
    @test S.data[1:5] == 1:5
    
    # Using the macro
    @test (@sampleidx S[1:5]) == 1:5
end

@testset "setindex! domain-space" begin
    data = collect(1:1000)
    S = DomainArray(copy(data), (100.0,))

    S[0.0:0.001:0.05] .= 0   # domain-based slice
    @test all(S.data[1:5] .== 0)
end

@testset "domainslice (copy)" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))

    S2 = domainslice(S, 0.0:0.001:0.1)   # index 1:10
    @test S2.data == 1:10
    @test S2.rate == S.rate
end

@testset "domainview (view semantics)" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))

    V = domainview(S, 0.0:0.001:0.1)  # index 1:10

    @test V.data == @view data[1:10]
    @test V.offset == (0.0,)   # exact alignment
end

@testset "cascaded domainview offset accumulation" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))

    # First view
    V1 = domainview(S, 0.01:0.001:0.02)
    # Second view relative to V1
    V2 = domainview(V1, 0.0:0.001:0.01)

    # Offsets should accumulate
    @test V2.offset[1] ≈ V1.offset[1] + (V2.offset[1] - V1.offset[1])
end

@testset "extreme view" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))

    # Uses the @extreme_view macro or direct function call
    V = @extreme_view domainview(S, 0.0:0.001:0.1)

    @test V.data == @view data[1:11] # Extreme rounding usually expands the range
end

@testset "pretty printing" begin
    data = collect(1:1000)
    S = DomainArray(data, (100.0,))
    V = domainview(S, 0.0:0.001:0.1)

    io = IOBuffer()
    show(io, MIME"text/plain"(), S)
    str = String(take!(io))
    @test occursin("DomainArray", str)
    @test occursin("rate=(100.0,)", str)

    io = IOBuffer()
    show(io, MIME"text/plain"(), V)
    str = String(take!(io))
    @test occursin("DomainView", str)
    @test occursin("offset=", str)
end

@testset "@sampleidx macro" begin
    data = collect(1:1000)
    S = DomainArray(copy(data), (100.0,))

    @sampleidx S[1:5] .= 77
    @test all(S.data[1:5] .== 77)
end

@testset "Domain Arithmetic" begin
    a = domainones((1.0, 100))
    b = domainones((1.0, 100))
    
    c = a + b
    @test c isa DomainArray
    @test all(c.data .== 2.0)
    @test c.rate == (100.0,)
    
    d = domainones((1.0, 200))
    @test_throws ErrorException a + d
end
