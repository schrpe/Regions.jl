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

    # Single region, single run: Run(col, rows) — col=5, rows=1:4
    regions = [Region([Run(5, 1:4)])]
    @test left(regions)   == 5
    @test right(regions)  == 5
    @test top(regions)    == 4
    @test bottom(regions) == 1
    @test bounds(regions) == (5, 4, 5, 1)

    # Single region, multiple runs spanning different columns
    regions = [Region([Run(3, 1:5), Run(9, 4:7)])]
    @test left(regions)   == 3
    @test right(regions)  == 9
    @test top(regions)    == 7
    @test bottom(regions) == 1
    @test bounds(regions) == (3, 7, 9, 1)

    # Two regions: bounds span both
    regions = [Region([Run(3, 1:5)]), Region([Run(9, 4:7)])]
    @test left(regions)   == 3
    @test right(regions)  == 9
    @test top(regions)    == 7
    @test bottom(regions) == 1
    @test bounds(regions) == (3, 7, 9, 1)

    # Three regions
    regions = [
        Region([Run(0, 0:1)]),
        Region([Run(5, 3:4)]),
        Region([Run(2, 1:6)])
    ]
    @test left(regions)   == 0
    @test right(regions)  == 5
    @test top(regions)    == 6
    @test bottom(regions) == 0
    @test bounds(regions) == (0, 6, 5, 0)

end # "bounds(Vector{Region})"

@testset "region_to_image" begin

    # Single-pixel region: col=1, row=1 → 1×1 image
    r = Region([Run(1, 1:1)])
    img = region_to_image(r)
    @test size(img) == (1, 1)
    @test img[1, 1] == Gray(true)

    # Vertical run: col=1, rows=1:3 → 3 rows × 1 col image
    r = Region([Run(1, 1:3)])
    img = region_to_image(r)
    @test size(img) == (3, 1)
    @test all(img .== Gray(true))

    # Solid 3×2 region: 2 columns × 3 rows
    r = Region([Run(1, 1:3), Run(2, 1:3)])
    img = region_to_image(r)
    @test size(img) == (3, 2)
    @test all(img .== Gray(true))

    # Region not at origin: image is cropped to bounding box
    r = Region([Run(5, 10:12)])
    img = region_to_image(r)
    @test size(img) == (3, 1)
    @test all(img .== Gray(true))

    # Sparse region: columns 1 and 3 only; column 2 stays zero
    r = Region([Run(1, 1:2), Run(3, 1:2)])
    img = region_to_image(r)
    @test size(img) == (2, 3)              # rows: 2-1+1=2, cols: 3-1+1=3
    @test all(img[:, 1] .== Gray(true))   # column 1 set
    @test all(img[:, 2] .== Gray(false))  # column 2 empty
    @test all(img[:, 3] .== Gray(true))   # column 3 set

    # Custom color: col=1, rows=1:2 → 2×1 image
    r = Region([Run(1, 1:2)])
    img = region_to_image(r, Gray(0.5))
    @test size(img) == (2, 1)
    @test img[1, 1] ≈ Gray(0.5)
    @test img[2, 1] ≈ Gray(0.5)

end # "region_to_image"

@testset "regions_to_image" begin

    # Single opaque region: 2 cols × 2 rows → 2×2 image
    r = Region([Run(1, 1:2), Run(2, 1:2)])
    img = regions_to_image([r], [RGBA{Float64}(1, 0, 0, 1)])
    @test size(img) == (2, 2)
    @test all(p -> p ≈ RGBA{Float64}(1, 0, 0, 1), img)

    # Background pixels remain zero
    r = Region([Run(1, 1:1)])
    img = regions_to_image([r], [RGBA{Float64}(1, 0, 0, 1)])
    @test size(img) == (1, 1)
    @test img[1, 1] ≈ RGBA{Float64}(1, 0, 0, 1)

    # Two non-overlapping regions: col 1 gets red, col 3 gets green, col 2 is empty
    r1 = Region([Run(1, 1:2)])
    r2 = Region([Run(3, 1:2)])
    img = regions_to_image([r1, r2], [RGBA{Float64}(1, 0, 0, 1), RGBA{Float64}(0, 1, 0, 1)])
    @test size(img) == (2, 3)
    @test all(p -> p ≈ RGBA{Float64}(1, 0, 0, 1), img[:, 1])
    @test all(p -> p ≈ RGBA{Float64}(0, 0, 0, 0), img[:, 2])
    @test all(p -> p ≈ RGBA{Float64}(0, 1, 0, 1), img[:, 3])

    # Color cycling: more regions than colors → single color applied to all
    r1 = Region([Run(1, 1:1)])
    r2 = Region([Run(2, 1:1)])
    r3 = Region([Run(3, 1:1)])
    img = regions_to_image([r1, r2, r3], [RGBA{Float64}(1, 0, 0, 1)])
    @test size(img) == (1, 3)
    @test all(p -> p ≈ RGBA{Float64}(1, 0, 0, 1), img)

end # "regions_to_image"
