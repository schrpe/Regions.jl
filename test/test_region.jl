# Unit tests for Region type and related functions.
# This file is supposed to be included from runtests.jl.

using Images: Gray, RGBA

@testset "Region" begin
    @test length(Region().runs) == 0
    @test length(Region(Run[]).runs) == 0
    @test length(Region(Run[], false).runs) == 0

    @test Region([Run(0, 0:0)]).complement == false
    @test Region([Run(0, 0:0)], false).complement == false
    @test Region([Run(0, 0:0)], true).complement == true

    @test length(Region([Run(0, 0:0)]).runs) == 1
    @test Region([Run(0, 0:0)]).runs[1].column == 0
    @test Region([Run(0, 0:0)]).runs[1].rows.start == 0
    @test Region([Run(0, 0:0)]).runs[1].rows.stop == 0

    @test length(Region([Run(1, 2:3)]).runs) == 1
    @test Region([Run(1, 2:3)]).runs[1].column == 1
    @test Region([Run(1, 2:3)]).runs[1].rows.start == 2
    @test Region([Run(1, 2:3)]).runs[1].rows.stop == 3

    @test Region([Run(0, 0:0)], false) == Region([Run(0, 0:0)], false)
    @test Region([Run(0, 0:0)], true) == Region([Run(0, 0:0)], true)
    @test Region([Run(0, 0:0)], false) != Region([Run(0, 0:0)], true)
    @test Region([Run(0, 0:0)], true) != Region([Run(0, 0:0)], false)
    @test Region([Run(0, 0:0)], false) != Region([Run(1, 2:3)], true)

    @test Region([Run(0, 0:0)], false) == copy(Region([Run(0, 0:0)], false))

    @test invert(Region([Run(0, 0:0)])).runs[1].column == 0
    @test invert(Region([Run(0, 0:0)])).runs[1].rows.start == 0
    @test invert(Region([Run(0, 0:0)])).runs[1].rows.stop == 0
    @test invert(Region([Run(1, 2:3)])).runs[1].column == -1
    @test invert(Region([Run(1, 2:3)])).runs[1].rows.start == -3
    @test invert(Region([Run(1, 2:3)])).runs[1].rows.stop == -2
    @test invert(invert(Region([Run(1, 2:3)]))).runs[1].column == 1
    @test invert(invert(Region([Run(1, 2:3)]))).runs[1].rows.start == 2
    @test invert(invert(Region([Run(1, 2:3)]))).runs[1].rows.stop == 3
    @test (-Region([Run(1, 2:3)])).runs[1].column == -1
    @test (-Region([Run(1, 2:3)])).runs[1].rows.start == -3
    @test (-Region([Run(1, 2:3)])).runs[1].rows.stop == -2
    @test (- -Region([Run(1, 2:3)])).runs[1].column == 1
    @test (- -Region([Run(1, 2:3)])).runs[1].rows.start == 2
    @test (- -Region([Run(1, 2:3)])).runs[1].rows.stop == 3

    # translate: b[1]=x-offset (→ column), b[2]=y-offset (→ rows)
    @test translate(Region([Run(1, 1:2), Run(2, 3:4)]), [-5, -6]) == Region([Run(-4, -5:-4), Run(-3, -3:-2)])
    @test Region([Run(1, 1:2), Run(2, 3:4)]) - [5, 6] == Region([Run(-4, -5:-4), Run(-3, -3:-2)])
    @test Region([Run(1, 1:2), Run(2, 3:4)]) + [5, 6] == Region([Run(6, 7:8), Run(7, 9:10)])

    # center: moves bounding-box midpoint to origin via integer division
    let c = center(Region([Run(3, 2:4), Run(4, 2:4), Run(5, 2:4)]))
        @test left(c) == -1 && right(c) == 1
        @test bottom(c) == -1 && top(c) == 1
    end
    # even column span: columns 10–11 → midpoint = (10+11)÷2 = 10, shift −10 → 0:1
    let c = center(Region([Run(10, 5:6), Run(11, 5:6)]))
        @test left(c) == 0 && right(c) == 1
    end
    # single pixel is already trivially centerable
    @test center(Region([Run(7, 3:3)])) == Region([Run(0, 0:0)])
    # shape is preserved: same area
    let r = Region([Run(c, 1:3) for c in 1:5])
        @test area(center(r)) == area(r)
    end

    # contains: Run(column, rows) — contains(r, x, y) checks column==x and y∈rows
    @test !contains(Region([Run(0, 0:-1)]), 0, -1)
    @test !contains(Region([Run(0, 0:-1)]), 0, 0)
    @test !contains(Region([Run(0, 0:-1)]), 0, 1)
    @test !contains(Region([Run(0, 0:0)]), -1, 0)
    @test !contains(Region([Run(0, 0:0)]), 0, -1)
    @test contains(Region([Run(0, 0:0)]), 0, 0)
    @test !contains(Region([Run(0, 0:0)]), 0, 1)
    @test !contains(Region([Run(0, 0:0)]), 1, 0)
    @test !contains(Region([Run(0, 0:1)]), -1, 0)
    @test !contains(Region([Run(0, 0:1)]), 0, -1)
    @test contains(Region([Run(0, 0:1)]), 0, 0)
    @test contains(Region([Run(0, 0:1)]), 0, 1)
    @test !contains(Region([Run(0, 0:1)]), 0, 2)
    @test !contains(Region([Run(0, 0:1)]), 1, 0)
    @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 0, 0)
    @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 1, 0)
    @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 0, 1)
    @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 1, 1)
    @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 0)
    @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), 2, 0)
    @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 1)
    @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), 2, 1)
    @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), 0, -1)
    @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), 0, 2)

    @test [0, -1] ∉ Region([Run(0, 0:-1)])
    @test [0, 0] ∉ Region([Run(0, 0:-1)])
    @test [0, 1] ∉ Region([Run(0, 0:-1)])
    @test [-1, -1] ∉ Region([Run(0, 0:0)])
    @test [0, 1] ∉ Region([Run(0, 0:0)])
    @test [-1, 0] ∉ Region([Run(0, 0:0)])
    @test [0, 0] ∈ Region([Run(0, 0:0)])
    @test [0, 1] ∉ Region([Run(0, 0:0)])
    @test [1, 0] ∉ Region([Run(0, 0:0)])
    @test [-1, 0] ∉ Region([Run(0, 0:1)])
    @test [0, -1] ∉ Region([Run(0, 0:1)])
    @test [0, 0] ∈ Region([Run(0, 0:1)])
    @test [0, 1] ∈ Region([Run(0, 0:1)])
    @test [0, 2] ∉ Region([Run(0, 0:1)])
    @test [1, 0] ∉ Region([Run(0, 0:1)])
    @test [0, 0] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [1, 0] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [0, 1] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [1, 1] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 0] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [2, 0] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 1] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [2, 1] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [0, -1] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [0, 2] ∉ Region([Run(0, 0:1), Run(1, 0:1)])

    @test complement(Region([Run(0, 0:1)])).complement == true;
    @test complement(Region([Run(0, 0:1)])).runs == Region([Run(0, 0:1)]).runs;
    @test complement(Region([Run(0, 0:1)], false)).complement == true;
    @test complement(Region([Run(0, 0:1)], false)).runs == Region([Run(0, 0:1)]).runs;
    @test complement(Region([Run(0, 0:1)], true)).complement == false;
    @test complement(Region([Run(0, 0:1)], true)).runs == Region([Run(0, 0:1)]).runs;

    @test Regions.merge([Run(0, 0:1)], [Run(1, 0:1)]) == [Run(0, 0:1), Run(1, 0:1)]
    @test Regions.merge([Run(1, 0:1)], [Run(0, 0:1)]) == [Run(0, 0:1), Run(1, 0:1)]
    @test Regions.merge([Run(0, 0:1), Run(1, 0:1)], [Run(0, 1:2), Run(1, 1:2)]) == [Run(0, 0:1), Run(0, 1:2), Run(1, 0:1), Run(1, 1:2)]
    @test Regions.merge([Run(0, 1:2), Run(1, 1:2)], [Run(0, 0:1), Run(1, 0:1)]) == [Run(0, 0:1), Run(0, 1:2), Run(1, 0:1), Run(1, 1:2)]

    @test sort([Run(0, 0:1), Run(1, 0:1)]) == [Run(0, 0:1), Run(1, 0:1)]
    @test sort([Run(1, 0:1), Run(0, 0:1)]) == [Run(0, 0:1), Run(1, 0:1)]
    a = [Run(0, 0:1), Run(1, 0:1)]; sort!(a); @test a == [Run(0, 0:1), Run(1, 0:1)]
    a = [Run(1, 0:1), Run(0, 0:1)]; sort!(a); @test a == [Run(0, 0:1), Run(1, 0:1)]

    a = [Run(0, 0:1)]; Regions.pack!(a); @test a == [Run(0, 0:1)]
    a = [Run(0, 0:1), Run(0, 1:2)]; Regions.pack!(a); @test a == [Run(0, 0:2)]
    a = [Run(0, 0:1), Run(0, 2:3)]; Regions.pack!(a); @test a == [Run(0, 0:3)]
    a = [Run(0, 0:3), Run(0, 0:1)]; Regions.pack!(a); @test a == [Run(0, 0:3)]
    a = [Run(0, 0:3), Run(0, 1:2)]; Regions.pack!(a); @test a == [Run(0, 0:3)]
    a = [Run(0, 0:3), Run(0, 2:3)]; Regions.pack!(a); @test a == [Run(0, 0:3)]
    a = [Run(0, 0:3), Run(0, 0:3)]; Regions.pack!(a); @test a == [Run(0, 0:3)]
    a = [Run(0, 0:1), Run(0, 3:4)]; Regions.pack!(a); @test a == [Run(0, 0:1), Run(0, 3:4)]

    @test union([Run(0, 0:1), Run(0, 0:1)]) == [Run(0, 0:1)]
    @test union([Run(0, 0:1), Run(1, 0:1)]) == [Run(0, 0:1), Run(1, 0:1)]
    @test union([Run(0, 0:1), Run(1, 0:1)], [Run(0, 1:2), Run(1, 1:2)]) == [Run(0, 0:2), Run(1, 0:2)]

    a = [Run(0, 0:1)]; Regions.intersect!(a); @test a == Run[]
    a = [Run(0, 0:1), Run(0, 2:3)]; Regions.intersect!(a); @test a == Run[]
    a = [Run(0, 0:1), Run(0, 1:2)]; Regions.intersect!(a); @test a == [Run(0, 1:1)]
    a = [Run(0, 0:3), Run(0, 1:2)]; Regions.intersect!(a); @test a == [Run(0, 1:2)]

    @test intersection([Run(0, 0:1)], [Run(1, 0:1)]) == Run[]
    @test intersection([Run(0, 0:1)], [Run(0, 0:1)]) == [Run(0, 0:1)]

    @test difference(Run[], Run[]) == Run[]
    @test difference([Run(0, 0:1)], Run[]) == [Run(0, 0:1)]
    @test difference(Run[], [Run(0, 0:1)]) == Run[]
    @test difference([Run(0, 0:1)], [Run(0, 0:1)]) == Run[]
    @test difference([Run(0, 0:2)], [Run(0, 0:0)]) == [Run(0, 1:2)]
    @test difference([Run(0, 0:2)], [Run(0, 1:1)]) == [Run(0, 0:0), Run(0, 2:2)]
    @test difference([Run(0, 0:2)], [Run(0, 2:2)]) == [Run(0, 0:1)]

end # "Region"

# Test fixtures: A = column 0, rows 0..5; B = column 0, rows 3..8
# Derived facts (used throughout):
#   A ∩ B = Run(0, 3:5)     A ∪ B = Run(0, 0:8)
#   A \ B = Run(0, 0:2)     B \ A = Run(0, 6:8)

@testset "Complement" begin

    A = Region([Run(0, 0:5)])
    B = Region([Run(0, 3:8)])

    # complement() flips the complement flag and preserves runs
    @test complement(A).complement == true
    @test complement(A).runs == A.runs
    @test complement(complement(A)) == A

    # contains() inverts for complement regions
    cA = complement(A)
    @test !contains(cA, 0, 2)   # row 2 in col 0 is inside A → not in complement(A)
    @test contains(cA, 0, 7)    # row 7 in col 0 is outside A → in complement(A)
    @test contains(cA, 1, 0)    # col 1 has no run → in complement(A)

    # union(complement(A), complement(B)) = complement(A ∩ B)   [DeMorgan]
    r = union(complement(A), complement(B))
    @test r.complement == true
    @test r.runs == intersection(A, B).runs   # runs of A ∩ B = [Run(0, 3:5)]

    # union(complement(A), B) = complement(A \ B)
    r = union(complement(A), B)
    @test r.complement == true
    @test r.runs == difference(A, B).runs     # runs of A \ B = [Run(0, 0:2)]

    # union(A, complement(B)) = complement(B \ A)
    r = union(A, complement(B))
    @test r.complement == true
    @test r.runs == difference(B, A).runs     # runs of B \ A = [Run(0, 6:8)]

    # intersection(complement(A), complement(B)) = complement(A ∪ B)   [DeMorgan]
    r = intersection(complement(A), complement(B))
    @test r.complement == true
    @test r.runs == union(A, B).runs          # runs of A ∪ B = [Run(0, 0:8)]

    # intersection(complement(A), B) = B \ A
    r = intersection(complement(A), B)
    @test r.complement == false
    @test r.runs == difference(B, A).runs     # [Run(0, 6:8)]

    # intersection(A, complement(B)) = A \ B
    r = intersection(A, complement(B))
    @test r.complement == false
    @test r.runs == difference(A, B).runs     # [Run(0, 0:2)]

    # difference(complement(A), complement(B)) = B \ A
    r = difference(complement(A), complement(B))
    @test r.complement == false
    @test r.runs == difference(B, A).runs     # [Run(0, 6:8)]

    # difference(complement(A), B) = complement(A ∪ B)
    r = difference(complement(A), B)
    @test r.complement == true
    @test r.runs == union(A, B).runs          # runs of A ∪ B = [Run(0, 0:8)]

    # difference(A, complement(B)) = A ∩ B
    r = difference(A, complement(B))
    @test r.complement == false
    @test r.runs == intersection(A, B).runs   # [Run(0, 3:5)]

    # Verify with contains() that membership is correct for a sample case
    # intersection(A, complement(B)) should be A \ B = column 0, rows 0..2
    r = intersection(A, complement(B))
    @test contains(r, 0, 0)    # (col=0, row=0) ∈ A \ B
    @test contains(r, 0, 2)    # (col=0, row=2) ∈ A \ B
    @test !contains(r, 0, 3)   # (col=0, row=3) ∉ A \ B  (it's in B)
    @test !contains(r, 0, 7)   # (col=0, row=7) ∉ A \ B  (it's only in B)

end # "Complement"

@testset "region_from_box" begin

    # Basic box: columns 1..4, rows 2..3 → 4 vertical runs (one per column)
    r = region_from_box(1, 3, 4, 2)
    @test length(r.runs) == 4
    @test r.runs[1] == Run(1, 2:3)
    @test r.runs[4] == Run(4, 2:3)
    @test r.complement == false

    # Narrow box: columns 0..2, rows 0..1 → 3 vertical runs
    r = region_from_box(0, 1, 2, 0)
    @test length(r.runs) == 3
    @test r.runs[1] == Run(0, 0:1)
    @test r.runs[3] == Run(2, 0:1)

    # Negative coordinates: columns -4..-2, rows -3..-1 → 3 vertical runs
    r = region_from_box(-4, -1, -2, -3)
    @test length(r.runs) == 3
    @test r.runs[1] == Run(-4, -3:-1)
    @test r.runs[2] == Run(-3, -3:-1)
    @test r.runs[3] == Run(-2, -3:-1)

    # Bounds of the resulting region match box arguments
    r = region_from_box(2, 7, 9, 4)
    @test left(r)   == 2
    @test right(r)  == 9
    @test bottom(r) == 4
    @test top(r)    == 7

    # Every pixel inside the box is contained
    r = region_from_box(0, 2, 3, 0)
    @test contains(r, 0, 0)
    @test contains(r, 3, 2)
    @test contains(r, 1, 1)

    # Pixels outside the box are not contained
    @test !contains(r, -1, 0)
    @test !contains(r, 4, 0)
    @test !contains(r, 0, -1)
    @test !contains(r, 0, 3)

    # Assertion fires when bottom >= top
    @test_throws AssertionError region_from_box(0, 1, 5, 1)
    @test_throws AssertionError region_from_box(0, 0, 5, 1)

    # Assertion fires when left >= right
    @test_throws AssertionError region_from_box(5, 2, 5, 0)
    @test_throws AssertionError region_from_box(6, 2, 5, 0)

end # "region_from_box"

@testset "region_from_circle" begin

    # Radius 0: single pixel at center
    r = region_from_circle(0, 0, 0)
    @test length(r.runs) == 1
    @test r.runs[1] == Run(0, 0:0)
    @test r.complement == false

    # Radius 2 centered at origin: known run structure
    r = region_from_circle(0, 0, 2)
    @test length(r.runs) == 5
    @test r.runs[1] == Run(-2, 0:0)
    @test r.runs[2] == Run(-1, -1:1)
    @test r.runs[3] == Run(0, -2:2)
    @test r.runs[4] == Run(1, -1:1)
    @test r.runs[5] == Run(2, 0:0)

    # Non-origin center: runs shift accordingly
    r = region_from_circle(5, 10, 2)
    @test r.runs[1] == Run(3, 10:10)
    @test r.runs[3] == Run(5, 8:12)
    @test r.runs[5] == Run(7, 10:10)

    # Bounds match the bounding box of the circle
    r = region_from_circle(3, 4, 5)
    @test left(r)   == 3 - 5
    @test right(r)  == 3 + 5
    @test bottom(r) == 4 - 5
    @test top(r)    == 4 + 5

    # Interior points are contained
    r = region_from_circle(0, 0, 5)
    @test contains(r, 0, 0)
    @test contains(r, 0, 5)
    @test contains(r, 3, 4)   # 3² + 4² == 25 == r²

    # Points outside are not contained
    @test !contains(r, 4, 4)  # 4² + 4² == 32 > 25
    @test !contains(r, 0, 6)

    # Negative radius is forbidden
    @test_throws AssertionError region_from_circle(0, 0, -1)

end # "region_from_circle"

@testset "region_from_polygon" begin

    # Triangle (0,0),(4,0),(2,4): four runs, col 4 excluded by half-open rule
    r = region_from_polygon([(0,0), (4,0), (2,4)])
    @test length(r.runs) == 4
    @test r.runs[1] == Run(0, 0:0)
    @test r.runs[2] == Run(1, 0:2)
    @test r.runs[3] == Run(2, 0:4)
    @test r.runs[4] == Run(3, 0:2)
    @test r.complement == false

    # Interior point is contained
    @test contains(r, 2, 2)
    @test contains(r, 1, 1)

    # Outside points are not contained
    @test !contains(r, 0, 2)   # col 0 only covers row 0
    @test !contains(r, 4, 0)   # col 4 excluded by half-open rule

    # Rectangle (0,0),(4,0),(4,3),(0,3): columns 0..3, rows 0:3
    r = region_from_polygon([(0,0), (4,0), (4,3), (0,3)])
    @test length(r.runs) == 4
    @test all(run -> run.rows == 0:3, r.runs)
    @test r.runs[1].column == 0
    @test r.runs[4].column == 3

    # Clockwise and counter-clockwise winding produce the same fill
    r_cw  = region_from_polygon([(0,0), (3,0), (3,3), (0,3)])
    r_ccw = region_from_polygon([(0,3), (3,3), (3,0), (0,0)])
    @test r_cw == r_ccw

    # Negative coordinates
    r = region_from_polygon([(-2,0), (2,0), (0,4)])
    @test contains(r, 0, 2)
    @test !contains(r, -3, 0)
    @test r.runs[1] == Run(-2, 0:0)
    @test r.runs[3] == Run(0, 0:4)

    # Fewer than 3 vertices is forbidden
    @test_throws AssertionError region_from_polygon([(0,0), (1,1)])

end # "region_from_polygon"

@testset "Set operations on empty regions" begin

    empty  = Region()
    single = Region([Run(0, 1:3)])

    # complement of empty region
    ce = complement(empty)
    @test ce.complement == true
    @test isempty(ce.runs)
    @test contains(ce, 0, 0)     # complement of empty contains everything
    @test contains(ce, 99, -99)

    # complement of complement of empty is empty again
    @test complement(ce) == empty

    # union: empty ∪ A = A
    @test union(empty, single) == single
    @test union(single, empty) == single
    @test union(empty, empty)  == empty

    # intersection: empty ∩ A = empty
    @test intersection(empty, single) == empty
    @test intersection(single, empty) == empty
    @test intersection(empty, empty)  == empty

    # difference: empty \ A = empty, A \ empty = A
    @test difference(empty, single) == empty
    @test difference(single, empty) == single
    @test difference(empty, empty)  == empty

    # union with complement(empty) = complement(empty) (everything)
    @test union(single, complement(empty)) == complement(empty)
    @test union(complement(empty), single) == complement(empty)

    # intersection with complement(empty) = identity
    @test intersection(single, complement(empty)) == single
    @test intersection(complement(empty), single) == single

    # difference A \ complement(empty) = empty  (removing "everything" leaves nothing)
    @test difference(single, complement(empty)) == empty

    # difference complement(empty) \ A = complement(A)  (everything minus A)
    @test difference(complement(empty), single) == complement(single)

end # "Set operations on empty regions"

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
