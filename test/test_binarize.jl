# Unit tests for binarize() and components().
# This file is supposed to be included from runtests.jl.

@testset "binarize" begin

    # Empty image produces empty region
    @test isempty(binarize(zeros(Float64, 0, 0), x -> x > 0.5))

    # All-dark image produces empty region
    @test isempty(binarize(zeros(Float64, 3, 4), x -> x > 0.5))

    # All-bright image produces one run per row
    img = ones(Float64, 2, 3)
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 2
    @test r.runs[1] == Run(1, 1:3)
    @test r.runs[2] == Run(2, 1:3)

    # Single pixel in the middle
    img = zeros(Float64, 3, 3)
    img[2, 2] = 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(2, 2:2)

    # Run touching left edge
    img = zeros(Float64, 1, 5)
    img[1, 1:3] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(1, 1:3)

    # Run touching right edge
    img = zeros(Float64, 1, 5)
    img[1, 3:5] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(1, 3:5)

    # Run spanning entire row
    img = zeros(Float64, 1, 4)
    img[1, :] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(1, 1:4)

    # Two separate runs in one row
    img = zeros(Float64, 1, 7)
    img[1, 1:2] .= 1.0
    img[1, 5:7] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 2
    @test r.runs[1] == Run(1, 1:2)
    @test r.runs[2] == Run(1, 5:7)

    # Multiple rows with different run extents
    img = zeros(Float64, 3, 5)
    img[1, 2:4] .= 1.0
    img[3, 1:5] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 2
    @test r.runs[1] == Run(1, 2:4)
    @test r.runs[2] == Run(3, 1:5)

    # Result is never a complement
    @test binarize(ones(Float64, 2, 2), x -> x > 0.5).complement == false

    # Custom predicate: threshold at <= 0.5
    img = ones(Float64, 1, 4) .* 0.3
    r = binarize(img, x -> x <= 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(1, 1:4)

end # "binarize"

@testset "components" begin

    # Empty region → no components
    @test length(components(Region(Run[]))) == 0

    # Single run → one component
    cs = components(Region([Run(1, 1:3)]))
    @test length(cs) == 1
    @test cs[1].runs == [Run(1, 1:3)]

    # Two vertically adjacent runs → one component
    cs = components(Region([Run(1, 1:5), Run(2, 1:5)]))
    @test length(cs) == 1

    # Two vertically adjacent runs with overlapping columns → one component
    cs = components(Region([Run(1, 1:5), Run(2, 3:8)]))
    @test length(cs) == 1

    # Two runs far apart in rows → two components
    cs = components(Region([Run(1, 1:3), Run(10, 1:3)]))
    @test length(cs) == 2

    # Two runs same row, far apart in columns → two components
    cs = components(Region([Run(1, 1:2), Run(1, 8:9)]))
    @test length(cs) == 2

    # Three disconnected runs → three components
    cs = components(Region([Run(1, 1:2), Run(1, 8:9), Run(10, 1:2)]))
    @test length(cs) == 3

    # Each component contains the correct runs
    r = Region([Run(1, 1:2), Run(3, 6:8)])
    cs = components(r)
    @test length(cs) == 2
    @test any(c -> c.runs == [Run(1, 1:2)], cs)
    @test any(c -> c.runs == [Run(3, 6:8)], cs)

    # dx parameter: runs touch within dx in columns → one component
    cs = components(Region([Run(1, 1:3), Run(2, 5:7)]), unsigned(2), unsigned(1))
    @test length(cs) == 1

    # dy parameter: runs touch within dy in rows → one component
    cs = components(Region([Run(1, 1:3), Run(3, 1:3)]), unsigned(1), unsigned(2))
    @test length(cs) == 1

    # Components are non-complement regions
    cs = components(Region([Run(1, 1:3)]))
    @test cs[1].complement == false

end # "components"
