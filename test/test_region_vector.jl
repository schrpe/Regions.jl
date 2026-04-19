# Unit tests for Vector{Region} operations: bounds, region_to_image, regions_to_image.
# This file is supposed to be included from runtests.jl.

using Images: Gray, RGBA

@testset "bounds(Vector{Region})" begin

    # Empty vector → missing
    @test ismissing(bounds(Region[]))
    @test ismissing(left(Region[]))
    @test ismissing(top(Region[]))
    @test ismissing(right(Region[]))
    @test ismissing(bottom(Region[]))

    # Single region with one run
    regions = [Region([Run(2, 3:5)])]
    @test left(regions)   == 3
    @test top(regions)    == 2
    @test right(regions)  == 5
    @test bottom(regions) == 2
    @test bounds(regions) == (3, 2, 5, 2)

    # Single region with multiple runs
    regions = [Region([Run(1, 3:5), Run(4, 7:9)])]
    @test left(regions)   == 3
    @test top(regions)    == 4
    @test right(regions)  == 9
    @test bottom(regions) == 1
    @test bounds(regions) == (3, 4, 9, 1)

    # Two regions: bounds span both
    regions = [Region([Run(1, 3:5)]), Region([Run(4, 7:9)])]
    @test left(regions)   == 3
    @test top(regions)    == 4
    @test right(regions)  == 9
    @test bottom(regions) == 1
    @test bounds(regions) == (3, 4, 9, 1)

    # Three regions
    regions = [
        Region([Run(0, 0:1)]),
        Region([Run(5, 3:4)]),
        Region([Run(2, 1:6)])
    ]
    @test left(regions)   == 0
    @test top(regions)    == 5
    @test right(regions)  == 6
    @test bottom(regions) == 0
    @test bounds(regions) == (0, 5, 6, 0)

end # "bounds(Vector{Region})"

@testset "region_to_image" begin

    # Single-pixel region → 1x1 image, pixel is set
    r = Region([Run(1, 1:1)])
    img = region_to_image(r)
    @test size(img) == (1, 1)
    @test img[1, 1] == Gray(true)

    # 1x3 region
    r = Region([Run(1, 1:3)])
    img = region_to_image(r)
    @test size(img) == (1, 3)
    @test all(img .== Gray(true))

    # 2x3 solid region
    r = Region([Run(1, 1:3), Run(2, 1:3)])
    img = region_to_image(r)
    @test size(img) == (2, 3)
    @test all(img .== Gray(true))

    # Region not at origin: image is cropped to bounding box
    r = Region([Run(5, 10:12)])
    img = region_to_image(r)
    @test size(img) == (1, 3)
    @test all(img .== Gray(true))

    # Sparse region: rows 1 and 3, row 2 stays zero
    r = Region([Run(1, 1:2), Run(3, 1:2)])
    img = region_to_image(r)
    @test size(img) == (3, 2)             # rows: 3-1+1=3, cols: 2-1+1=2
    @test all(img[1, :] .== Gray(true))   # bottom row (row=1 → index 1)
    @test all(img[2, :] .== Gray(false))  # row=2 has no runs → zero
    @test all(img[3, :] .== Gray(true))   # top row (row=3 → index 3)

    # Custom color
    r = Region([Run(1, 1:2)])
    img = region_to_image(r, Gray(0.5))
    @test size(img) == (1, 2)
    @test img[1, 1] ≈ Gray(0.5)
    @test img[1, 2] ≈ Gray(0.5)

end # "region_to_image"

@testset "regions_to_image" begin

    # Single opaque region fills with the color
    r = Region([Run(1, 1:2), Run(2, 1:2)])
    img = regions_to_image([r], [RGBA{Float64}(1, 0, 0, 1)])
    @test size(img) == (2, 2)
    @test all(p -> p ≈ RGBA{Float64}(1, 0, 0, 1), img)

    # Background pixels remain zero
    r = Region([Run(1, 1:1)])
    img = regions_to_image([r], [RGBA{Float64}(1, 0, 0, 1)])
    @test size(img) == (1, 1)
    @test img[1, 1] ≈ RGBA{Float64}(1, 0, 0, 1)

    # Two non-overlapping regions: each gets its own color
    r1 = Region([Run(1, 1:2)])
    r2 = Region([Run(3, 1:2)])
    img = regions_to_image([r1, r2], [RGBA{Float64}(1, 0, 0, 1), RGBA{Float64}(0, 1, 0, 1)])
    @test size(img) == (3, 2)   # rows 1 to 3
    @test all(p -> p ≈ RGBA{Float64}(1, 0, 0, 1), img[1, :])   # r1 at bottom row
    @test all(p -> p ≈ RGBA{Float64}(0, 0, 0, 0), img[2, :])   # empty row
    @test all(p -> p ≈ RGBA{Float64}(0, 1, 0, 1), img[3, :])   # r2 at top row

    # Color cycling: more regions than colors
    r1 = Region([Run(1, 1:1)])
    r2 = Region([Run(2, 1:1)])
    r3 = Region([Run(3, 1:1)])
    img = regions_to_image([r1, r2, r3], [RGBA{Float64}(1, 0, 0, 1)])
    @test size(img) == (3, 1)
    # All three get the same (only) color
    @test all(p -> p ≈ RGBA{Float64}(1, 0, 0, 1), img)

end # "regions_to_image"
