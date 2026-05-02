# Unit tests for morphological operations.
# This file is supposed to be included from runtests.jl.

@testset "Run _minkowski_addition" begin

    # Column and rows shift by the respective components
    @test Regions._minkowski_addition(Run(0, 0:0), Run(0, 0:0)) == Run(0, 0:0)
    @test Regions._minkowski_addition(Run(1, 2:4), Run(0, -1:1)) == Run(1, 1:5)
    @test Regions._minkowski_addition(Run(-1, 0:2), Run(2, 3:5)) == Run(1, 3:7)
    @test Regions._minkowski_addition(Run(3, -2:2), Run(-3, -2:2)) == Run(0, -4:4)

    # Single-pixel run ⊕ multi-row run = same multi-row run shifted
    @test Regions._minkowski_addition(Run(0, 5:5), Run(0, -2:2)) == Run(0, 3:7)

    # Commutativity
    a = Run(1, 0:3)
    b = Run(-1, 2:5)
    @test Regions._minkowski_addition(a, b) == Regions._minkowski_addition(b, a)

    # Result is never empty when inputs are non-empty
    @test !isempty(Regions._minkowski_addition(Run(0, 0:0), Run(0, 0:0)))

end # "Run _minkowski_addition"

@testset "Run _minkowski_subtraction" begin

    @test Regions._minkowski_subtraction(Run(3, 1:5), Run(1, 0:2)) == Run(2, 1:3)
    @test Regions._minkowski_subtraction(Run(0, -3:3), Run(0, -1:1)) == Run(0, -2:2)
    @test Regions._minkowski_subtraction(Run(2, 0:4), Run(2, 0:4)) == Run(0, 0:0)

    # Result is empty when b's row span exceeds a's
    @test isempty(Regions._minkowski_subtraction(Run(0, 0:1), Run(0, 0:3)))
    @test isempty(Regions._minkowski_subtraction(Run(0, 0:0), Run(0, -1:1)))

    # Inverse relationship: (A ⊕ B) ⊖ B = A when B is a single-row run
    a = Run(2, 1:3)
    b = Run(0, 0:0)
    @test Regions._minkowski_subtraction(Regions._minkowski_addition(a, b), b) == a

    # Column shifts cancel
    @test Regions._minkowski_subtraction(Run(5, 0:0), Run(3, 0:0)).column == 2

end # "Run _minkowski_subtraction"

# Shared fixtures used throughout the morphological tests:
#
#   pixel  — single pixel at the origin
#   box3   — 3×3 box centred at origin: cols -1:1, rows -1:1
#   box5   — 5×5 box centred at origin: cols -2:2, rows -2:2
#   box7   — 7×7 box centred at origin: cols -3:3, rows -3:3

@testset "_minkowski_addition(Region)" begin

    pixel = Region([Run(0, 0:0)])
    box3  = region_from_box(-1, -1, 1, 1)
    box5  = region_from_box(-2, -2, 2, 2)

    # Identity: A ⊕ {origin} = A
    @test Regions._minkowski_addition(pixel, Region([Run(0, 0:0)])) == pixel
    @test Regions._minkowski_addition(box3, Region([Run(0, 0:0)])) == box3

    # Single pixel ⊕ horizontal bar = the bar
    hbar = Region([Run(-1, 0:0), Run(0, 0:0), Run(1, 0:0)])
    @test Regions._minkowski_addition(pixel, hbar) == hbar

    # box3 ⊕ box3 = box5  (since invert(box3)==box3, dilation=mink_add here)
    @test Regions._minkowski_addition(box3, box3) == box5

    # Commutativity
    a = region_from_box(0, 0, 2, 2)
    b = region_from_box(-1, -1, 0, 1)
    @test Regions._minkowski_addition(a, b) == Regions._minkowski_addition(b, a)

    # Empty inputs
    @test Regions._minkowski_addition(Region(), box3) == Region()
    @test Regions._minkowski_addition(box3, Region()) == box3

    # Result contains origin if both contain origin
    @test contains(Regions._minkowski_addition(pixel, pixel), 0, 0)

end # "_minkowski_addition(Region)"

@testset "_minkowski_subtraction(Region)" begin

    pixel = Region([Run(0, 0:0)])
    box3  = region_from_box(-1, -1, 1, 1)
    box5  = region_from_box(-2, -2, 2, 2)

    # box5 ⊖ box3 = box3
    @test Regions._minkowski_subtraction(box5, box3) == box3

    # A ⊖ {origin} = A
    @test Regions._minkowski_subtraction(box3, Region([Run(0, 0:0)])) == box3
    @test Regions._minkowski_subtraction(pixel, Region([Run(0, 0:0)])) == pixel

    # Eroding a pixel by anything larger than itself → empty
    @test isempty(Regions._minkowski_subtraction(pixel, box3))

    # Empty first argument → empty result
    @test isempty(Regions._minkowski_subtraction(Region(), box3))

    # Empty second argument → unchanged
    @test Regions._minkowski_subtraction(box3, Region()) == box3

    # (A ⊕ B) ⊖ B ⊆ A   (not strict equality in general, but holds for convex shapes)
    a = region_from_box(0, 0, 3, 3)
    b = region_from_box(-1, -1, 1, 1)
    recovered = Regions._minkowski_subtraction(Regions._minkowski_addition(a, b), b)
    @test recovered == a

end # "_minkowski_subtraction(Region)"

@testset "erosion" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)
    box7 = region_from_box(-3, -3, 3, 3)

    # Erosion shrinks by one layer on each side
    @test erosion(box5, box3) == box3
    @test erosion(box7, box3) == box5

    # Erosion of a box by itself → single pixel
    @test erosion(box3, box3) == Region([Run(0, 0:0)])

    # Erosion of a pixel → empty (SE larger than region)
    @test isempty(erosion(Region([Run(0, 0:0)]), box3))

    # Erosion with {origin} is identity
    origin_se = Region([Run(0, 0:0)])
    @test erosion(box5, origin_se) == box5

    # Idempotency: eroding twice by box3 = eroding once by a 5×5 box
    @test erosion(erosion(box7, box3), box3) == erosion(box7, region_from_box(-2, -2, 2, 2))

    # Empty region → empty
    @test isempty(erosion(Region(), box3))

    # Interior pixels survive; boundary pixels are removed
    box9 = region_from_box(-4, -4, 4, 4)
    eroded = erosion(box9, box3)
    @test  contains(eroded, 0, 0)    # deep interior survives
    @test !contains(eroded, -4, 0)   # boundary removed
    @test !contains(eroded, 4, 0)
    @test !contains(eroded, 0, -4)
    @test !contains(eroded, 0, 4)

end # "erosion"

@testset "dilation" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)
    box7 = region_from_box(-3, -3, 3, 3)

    # Dilation grows by one layer
    @test dilation(box3, box3) == box5
    @test dilation(box5, box3) == box7

    # Dilation of a pixel by box3 = box3
    @test dilation(Region([Run(0, 0:0)]), box3) == box3

    # Dilation with {origin} is identity
    origin_se = Region([Run(0, 0:0)])
    @test dilation(box5, origin_se) == box5

    # Empty region → empty
    @test isempty(dilation(Region(), box3))

    # Duality: dilation(a, b) = complement(erosion(complement(a), b))  — not tested
    # as complement handling is not the focus here

    # New pixels appear just outside boundary
    dilated = dilation(box3, box3)
    @test  contains(dilated, -2, 0)
    @test  contains(dilated, 2, 0)
    @test  contains(dilated, 0, -2)
    @test  contains(dilated, 0, 2)
    @test !contains(dilated, -3, 0)
    @test !contains(dilated, 3, 0)

end # "dilation"

@testset "opening" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)

    # Opening a region larger than SE leaves it unchanged
    @test opening(box5, box3) == box5

    # Opening a region equal to SE leaves it unchanged
    @test opening(box3, box3) == box3

    # Opening removes an isolated pixel (too small for the SE)
    @test isempty(opening(Region([Run(0, 0:0)]), box3))

    # Result is always ⊆ input
    a = region_from_box(0, 0, 4, 4)
    result = opening(a, box3)
    for run in result.runs
        for row in run.rows
            @test contains(a, run.column, row)
        end
    end

    # Opening twice = opening once (idempotency)
    @test opening(opening(box5, box3), box3) == opening(box5, box3)

    # Empty input → empty output
    @test isempty(opening(Region(), box3))

end # "opening"

@testset "closing" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)

    # Closing a region without gaps leaves it unchanged
    @test closing(box5, box3) == box5
    @test closing(box3, box3) == box3

    # Closing bridges a gap of one column
    gapped = Region([Run(-1, 0:0), Run(1, 0:0)])
    c = closing(gapped, box3)
    @test contains(c, 0, 0)
    @test contains(c, -1, 0)
    @test contains(c, 1, 0)

    # Result always contains the original region
    a = region_from_box(0, 0, 4, 4)
    result = closing(a, box3)
    for run in a.runs
        for row in run.rows
            @test contains(result, run.column, row)
        end
    end

    # Closing twice = closing once (idempotency)
    @test closing(closing(box3, box3), box3) == closing(box3, box3)

    # Empty input → empty output
    @test isempty(closing(Region(), box3))

end # "closing"

@testset "morphological_gradient" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)

    grad = morphological_gradient(box5, box3)

    # Boundary pixels appear in the gradient
    @test  contains(grad, -2, 0)
    @test  contains(grad, 2, 0)
    @test  contains(grad, 0, -2)
    @test  contains(grad, 0, 2)

    # Deep interior pixels do not
    @test !contains(grad, 0, 0)
    @test !contains(grad, 1, 0)

    # Outer pixels (one outside the box) appear too
    @test  contains(grad, -3, 0)
    @test  contains(grad, 3, 0)

    # Gradient of a single pixel = box3 (dilation minus empty erosion)
    pixel_grad = morphological_gradient(Region([Run(0, 0:0)]), box3)
    @test pixel_grad == box3

    # Empty input → empty output
    @test isempty(morphological_gradient(Region(), box3))

end # "morphological_gradient"

@testset "inner_boundary" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)
    box7 = region_from_box(-3, -3, 3, 3)

    ib5 = inner_boundary(box5)
    ib7 = inner_boundary(box7)

    # Boundary pixels are inside
    @test  contains(ib5, -2, 0)
    @test  contains(ib5, 2, 0)
    @test  contains(ib5, 0, -2)
    @test  contains(ib5, 0, 2)

    # Interior pixels are not in the boundary
    @test !contains(ib5, 0, 0)
    @test !contains(ib5, 1, 0)

    # Inner boundary is a strict subset of the region
    for run in ib5.runs
        for row in run.rows
            @test contains(box5, run.column, row)
        end
    end

    # Calling inner_boundary does not mutate the input
    box5_copy = copy(box5)
    _ = inner_boundary(box5)
    @test box5 == box5_copy

    # Empty input → empty output
    @test isempty(inner_boundary(Region()))

end # "inner_boundary"

@testset "outer_boundary" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)

    ob = outer_boundary(box5)

    # Pixels just outside the box are in the outer boundary
    @test  contains(ob, -3, 0)
    @test  contains(ob, 3, 0)
    @test  contains(ob, 0, -3)
    @test  contains(ob, 0, 3)

    # Pixels on or inside the box are not
    @test !contains(ob, -2, 0)
    @test !contains(ob, 0, 0)

    # Outer boundary is disjoint from the region
    for run in ob.runs
        for row in run.rows
            @test !contains(box5, run.column, row)
        end
    end

    # Empty input → empty output
    @test isempty(outer_boundary(Region()))

end # "outer_boundary"

@testset "holes" begin

    box3  = region_from_box(-1, -1, 1, 1)
    outer = region_from_box(-3, -3, 3, 3)

    # Solid box has no holes
    @test isempty(holes(box3))
    @test isempty(holes(outer))

    # Frame = outer minus inner box → one hole
    frame = difference(region_from_box(-3, -3, 3, 3), region_from_box(-1, -1, 1, 1))
    hs = holes(frame)
    @test length(hs) == 1

    # The hole covers the inner box area
    hole = hs[1]
    @test contains(hole, 0, 0)
    @test contains(hole, -1, -1)
    @test contains(hole, 1, 1)

    # The hole does not extend beyond the inner box
    @test !contains(hole, -2, 0)
    @test !contains(hole, 2, 0)

    # Two separate holes
    # Build a region with two inner 1×1 gaps separated by a wall
    outer2  = region_from_box(-5, -5, 5, 5)
    hole1   = region_from_box(-4, -4, -3, -2)  # left hole: cols -4:-3, rows -4:-2
    hole2   = region_from_box(3, 3, 4, 4)      # right hole: cols 3:4, rows 3:4
    two_holes = difference(difference(region_from_box(-5, -5, 5, 5),
                                      region_from_box(-4, -4, -3, -2)),
                           region_from_box(3, 3, 4, 4))
    hs2 = holes(two_holes)
    @test length(hs2) == 2

    # Empty region → no holes
    @test isempty(holes(Region()))

    # Single pixel → no holes
    @test isempty(holes(Region([Run(0, 0:0)])))

    # Complement regions are not allowed
    @test_throws AssertionError holes(complement(box3))

end # "holes"

@testset "fill_holes" begin

    box3 = region_from_box(-1, -1, 1, 1)

    # Solid region has nothing to fill
    @test fill_holes(box3) == box3

    # Frame → filled region contains entire bounding box
    frame = difference(region_from_box(-3, -3, 3, 3), region_from_box(-1, -1, 1, 1))
    filled = fill_holes(frame)

    @test contains(filled, 0, 0)     # previously a hole
    @test contains(filled, -3, 0)    # original frame still there
    @test contains(filled, 3, 0)

    # The filled region is a superset of the frame
    for run in frame.runs
        for row in run.rows
            @test contains(filled, run.column, row)
        end
    end

    # Filling does not mutate the original
    frame2 = difference(region_from_box(-3, -3, 3, 3), region_from_box(-1, -1, 1, 1))
    frame2_runs_before = length(frame2.runs)
    fill_holes(frame2)
    @test length(frame2.runs) == frame2_runs_before

    # Empty region → empty
    @test isempty(fill_holes(Region()))

    # Complement regions are not allowed
    @test_throws AssertionError fill_holes(complement(box3))

end # "fill_holes"

@testset "Vector{Region} morphological operations" begin

    box3 = region_from_box(-1, -1, 1, 1)
    box5 = region_from_box(-2, -2, 2, 2)
    se   = box3

    # Each operation reduces the two-element vector [box5, pixel] appropriately
    pixel = Region([Run(0, 0:0)])
    two   = [box5, pixel]

    # erosion drops the pixel (too small), keeps the box
    eroded = erosion(two, se)
    @test length(eroded) == 1
    @test eroded[1] == erosion(box5, se)

    # dilation keeps both
    dilated = dilation(two, se)
    @test length(dilated) == 2

    # opening drops the pixel
    opened = opening(two, se)
    @test length(opened) == 1

    # closing keeps both
    closed = closing(two, se)
    @test length(closed) == 2

    # _minkowski_addition keeps both
    mink_add = Regions._minkowski_addition(two, se)
    @test length(mink_add) == 2

    # _minkowski_subtraction drops the pixel
    mink_sub = Regions._minkowski_subtraction(two, se)
    @test length(mink_sub) == 1

    # morphological_gradient: each non-empty region produces a result
    grad = morphological_gradient([box5], se)
    @test length(grad) == 1

    # inner_boundary: each non-empty region produces a result
    @test length(inner_boundary([box5, box3])) == 2

    # outer_boundary: each non-empty region produces a result
    @test length(outer_boundary([box5, box3])) == 2

    # fill_holes: applies per region, always same count
    frame = difference(region_from_box(-3, -3, 3, 3), region_from_box(-1, -1, 1, 1))
    filled_vec = fill_holes([frame, box3])
    @test length(filled_vec) == 2
    @test contains(filled_vec[1], 0, 0)   # frame hole filled
    @test contains(filled_vec[2], 0, 0)   # box3 unchanged (no holes)

    # empty vector → empty vector
    @test isempty(erosion(Region[], se))
    @test isempty(dilation(Region[], se))

end # "Vector{Region} morphological operations"
