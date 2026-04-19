# Unit tests for binarize() and components().
# This file is supposed to be included from runtests.jl.

@testset "binarize" begin

    # Empty image produces empty region
    @test isempty(binarize(zeros(Float64, 0, 0), x -> x > 0.5))

    # All-dark image produces empty region
    @test isempty(binarize(zeros(Float64, 3, 4), x -> x > 0.5))

    # All-bright 2×3 image: 3 columns → 3 vertical runs (one per column)
    img = ones(Float64, 2, 3)
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 3
    @test r.runs[1] == Run(1, 1:2)
    @test r.runs[2] == Run(2, 1:2)
    @test r.runs[3] == Run(3, 1:2)

    # Single bright pixel at img[2, 3] (row=2, col=3) in 4×4 image
    img = zeros(Float64, 4, 4)
    img[2, 3] = 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(3, 2:2)

    # Vertical run touching top of column: img[1:3, 2] in 5×3 image
    img = zeros(Float64, 5, 3)
    img[1:3, 2] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(2, 1:3)

    # Vertical run touching bottom of column: img[3:5, 2] in 5×3 image
    img = zeros(Float64, 5, 3)
    img[3:5, 2] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(2, 3:5)

    # Vertical run spanning entire column: img[:, 2] in 4×3 image
    img = zeros(Float64, 4, 3)
    img[:, 2] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(2, 1:4)

    # Two separate vertical runs in one column: rows 1:2 and 5:7 in a 7×1 image
    img = zeros(Float64, 7, 1)
    img[1:2, 1] .= 1.0
    img[5:7, 1] .= 1.0
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 2
    @test r.runs[1] == Run(1, 1:2)
    @test r.runs[2] == Run(1, 5:7)

    # Multiple columns with different run extents
    img = zeros(Float64, 5, 3)
    img[2:4, 1] .= 1.0   # col 1: rows 2..4
    img[1:5, 3] .= 1.0   # col 3: all rows
    r = binarize(img, x -> x > 0.5)
    @test length(r.runs) == 2
    @test r.runs[1] == Run(1, 2:4)
    @test r.runs[2] == Run(3, 1:5)

    # Result is never a complement
    @test binarize(ones(Float64, 2, 2), x -> x > 0.5).complement == false

    # Custom predicate: threshold at <= 0.5
    img = ones(Float64, 4, 1) .* 0.3
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

    # Two column-adjacent runs with overlapping rows → one component
    cs = components(Region([Run(1, 1:5), Run(2, 1:5)]))
    @test length(cs) == 1

    # Two column-adjacent runs with partially overlapping rows → one component
    cs = components(Region([Run(1, 1:5), Run(2, 3:8)]))
    @test length(cs) == 1

    # Two runs far apart in columns → two components
    cs = components(Region([Run(1, 1:3), Run(10, 1:3)]))
    @test length(cs) == 2

    # Two runs in same column, far apart in rows → two components
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

    # dx parameter: runs connect within dx=2 columns → one component
    cs = components(Region([Run(1, 1:3), Run(3, 1:3)]), unsigned(2), unsigned(1))
    @test length(cs) == 1

    # dy parameter: runs connect within dy=2 rows → one component
    cs = components(Region([Run(1, 1:3), Run(1, 5:7)]), unsigned(1), unsigned(2))
    @test length(cs) == 1

    # Components are non-complement regions
    cs = components(Region([Run(1, 1:3)]))
    @test cs[1].complement == false

end # "components"
