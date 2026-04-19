# Unit tests for region_from_box() and set operations on empty regions.
# This file is supposed to be included from runtests.jl.

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
