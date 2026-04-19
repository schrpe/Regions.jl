# Unit tests for Run type.
# This file is supposed to be included from runtests.jl.

@testset "Run" begin

    # Field access
    @test Run(0, 0:0).column == 0
    @test Run(0, 0:0).rows.start == 0
    @test Run(0, 0:0).rows.stop == 0

    # Empty run (empty row range)
    @test Run(0, 0:-1).rows == 0:-1
    @test Run(0, 0:-1).rows.start == 0
    @test Run(0, 0:-1).rows.stop == -1
    @test length(Run(0, 0:-1).rows) == 0
    @test isempty(Run(0, 0:-1).rows)

    # Single-element run
    @test Run(0, 0:0).rows == 0:0
    @test Run(0, 0:0).rows.start == 0
    @test Run(0, 0:0).rows.stop == 0
    @test length(Run(0, 0:0).rows) == 1
    @test !isempty(Run(0, 0:0).rows)

    # Two-element run
    @test Run(0, 0:1).rows == 0:1
    @test Run(0, 0:1).rows.start == 0
    @test Run(0, 0:1).rows.stop == 1
    @test length(Run(0, 0:1).rows) == 2
    @test !isempty(Run(0, 0:1).rows)

    # Equality
    @test Run(0, 0:1) == Run(0, 0:1)
    @test Run(0, 0:1) ≠ Run(1, 0:1)   # different column
    @test Run(0, 0:1) ≠ Run(0, 1:2)   # different rows

    # isless — sorted by column first, then rows.start
    @test Run(0, 0:1) < Run(1, 0:1)
    @test Run(0, 0:1) ≤ Run(1, 0:1)
    @test Run(0, 0:1) ≤ Run(0, 0:1)

    @test Run(0, 0:1) < Run(0, 1:2)
    @test Run(0, 0:1) ≤ Run(0, 1:2)
    @test Run(0, 0:1) ≤ Run(0, 0:1)

    @test Run(1, 0:1) > Run(0, 0:1)
    @test Run(1, 0:1) ≥ Run(0, 0:1)
    @test Run(0, 0:1) ≥ Run(0, 0:1)

    @test Run(0, 1:2) > Run(0, 0:1)
    @test Run(0, 1:2) ≥ Run(0, 0:1)
    @test Run(0, 0:1) ≥ Run(0, 0:1)

    # translate — [x, y] offsets column by x, rows by y
    @test translate(Run(1, 1:2), [-5, -6]) == Run(-4, -5:-4)
    @test translate(Run(1, 1:2), [5, 6])   == Run(6, 7:8)
    @test Run(1, 1:2) - [5, 6] == Run(-4, -5:-4)
    @test Run(1, 1:2) + [5, 6] == Run(6, 7:8)

    # invert (symmetric — negates both column and rows)
    @test -Run(1, 1:2) == Run(-1, -2:-1)
    @test -Run(-1, -1:0) == Run(1, 0:1)
    @test -(-(Run(1, 1:2))) == Run(1, 1:2)

    @test invert(Run(1, 1:2)) == Run(-1, -2:-1)
    @test invert(Run(-1, -1:0)) == Run(1, 0:1)
    @test invert(invert(Run(1, 1:2))) == Run(1, 1:2)

    # contains — checks column == x and y ∈ rows
    @test !contains(Run(0, 0:-1), 0, -1)   # empty run
    @test !contains(Run(0, 0:-1), 0, 0)
    @test !contains(Run(0, 0:-1), 0, 1)
    @test !contains(Run(0, 0:0), -1, -1)   # wrong column
    @test !contains(Run(0, 0:0), 0, -1)    # row before range
    @test !contains(Run(0, 0:0), -1, 0)    # wrong column
    @test  contains(Run(0, 0:0), 0, 0)
    @test !contains(Run(0, 0:0), 0, 1)     # row after range
    @test !contains(Run(0, 0:0), 1, 0)     # wrong column
    @test !contains(Run(0, 0:1), -1, 0)    # wrong column
    @test !contains(Run(0, 0:1), 0, -1)    # row before range
    @test  contains(Run(0, 0:1), 0, 0)
    @test  contains(Run(0, 0:1), 0, 1)
    @test !contains(Run(0, 0:1), 0, 2)     # row after range
    @test !contains(Run(0, 0:1), 1, 0)     # wrong column

    # ∈ operator (same checks via vector syntax [x, y])
    @test [0, -1] ∉ Run(0, 0:-1)
    @test [0, 0]  ∉ Run(0, 0:-1)
    @test [0, 1]  ∉ Run(0, 0:-1)
    @test [-1,-1] ∉ Run(0, 0:0)
    @test [0, -1] ∉ Run(0, 0:0)
    @test [-1, 0] ∉ Run(0, 0:0)
    @test [0,  0] ∈  Run(0, 0:0)
    @test [0,  1] ∉ Run(0, 0:0)
    @test [1,  0] ∉ Run(0, 0:0)
    @test [-1, 0] ∉ Run(0, 0:1)
    @test [0, -1] ∉ Run(0, 0:1)
    @test [0,  0] ∈  Run(0, 0:1)
    @test [0,  1] ∈  Run(0, 0:1)
    @test [0,  2] ∉ Run(0, 0:1)
    @test [1,  0] ∉ Run(0, 0:1)

    # isoverlapping — requires same column and overlapping rows
    @test !isoverlapping(Run(0, 0:1), Run(0, 6:7))
    @test !isoverlapping(Run(0, 1:2), Run(0, 5:6))
    @test !isoverlapping(Run(0, 2:3), Run(0, 4:5))
    @test !isoverlapping(Run(-1, 2:3), Run(0, 3:4))   # different column
    @test !isoverlapping(Run(0, 2:3), Run(-1, 3:4))   # different column
    @test  isoverlapping(Run(0, 2:3), Run(0, 3:4))
    @test !isoverlapping(Run(1, 2:3), Run(0, 3:4))    # different column
    @test !isoverlapping(Run(0, 2:3), Run(1, 3:4))    # different column
    @test !isoverlapping(Run(-1, 3:4), Run(0, 3:4))   # different column
    @test !isoverlapping(Run(0, 3:4), Run(-1, 3:4))   # different column
    @test  isoverlapping(Run(0, 3:4), Run(0, 3:4))
    @test !isoverlapping(Run(0, 3:4), Run(1, 3:4))    # different column
    @test !isoverlapping(Run(1, 3:4), Run(0, 3:4))    # different column
    @test !isoverlapping(Run(0, 4:5), Run(0, 2:3))
    @test !isoverlapping(Run(0, 5:6), Run(0, 1:2))
    @test !isoverlapping(Run(0, 6:7), Run(0, 0:1))

    # istouching — columns within 1 AND rows touching
    @test !istouching(Run(0, 0:1), Run(0, 6:7))
    @test !istouching(Run(0, 1:2), Run(0, 5:6))
    @test !istouching(Run(0, 2:3), Run(2, 4:5))    # column gap = 2
    @test  istouching(Run(0, 2:3), Run(-1, 4:5))
    @test  istouching(Run(0, 2:3), Run(1, 4:5))
    @test  istouching(Run(0, 2:3), Run(0, 4:5))
    @test  istouching(Run(1, 2:3), Run(0, 4:5))
    @test  istouching(Run(-1, 2:3), Run(0, 4:5))
    @test !istouching(Run(2, 2:3), Run(0, 4:5))    # column gap = 2
    @test !istouching(Run(-2, 2:3), Run(0, 3:4))   # column gap = 2
    @test !istouching(Run(0, 2:3), Run(-2, 3:4))   # column gap = 2
    @test  istouching(Run(-1, 2:3), Run(0, 3:4))
    @test  istouching(Run(0, 2:3), Run(-1, 3:4))
    @test  istouching(Run(0, 2:3), Run(0, 3:4))
    @test  istouching(Run(0, 2:3), Run(1, 3:4))
    @test  istouching(Run(1, 2:3), Run(0, 3:4))
    @test !istouching(Run(0, 2:3), Run(2, 3:4))
    @test !istouching(Run(2, 2:3), Run(0, 3:4))
    @test !istouching(Run(0, 3:4), Run(-2, 3:4))
    @test !istouching(Run(-2, 3:4), Run(0, 3:4))
    @test  istouching(Run(0, 3:4), Run(-1, 3:4))
    @test  istouching(Run(-1, 3:4), Run(0, 3:4))
    @test  istouching(Run(0, 3:4), Run(0, 3:4))
    @test  istouching(Run(0, 3:4), Run(1, 3:4))
    @test  istouching(Run(1, 3:4), Run(0, 3:4))
    @test !istouching(Run(0, 3:4), Run(2, 3:4))
    @test !istouching(Run(2, 3:4), Run(0, 3:4))
    @test !istouching(Run(0, 4:5), Run(-2, 2:3))
    @test !istouching(Run(-2, 4:5), Run(0, 2:3))
    @test  istouching(Run(0, 4:5), Run(-1, 2:3))
    @test  istouching(Run(-1, 4:5), Run(0, 2:3))
    @test  istouching(Run(0, 4:5), Run(0, 2:3))
    @test  istouching(Run(0, 4:5), Run(1, 2:3))
    @test  istouching(Run(1, 4:5), Run(0, 2:3))
    @test !istouching(Run(0, 4:5), Run(2, 2:3))
    @test !istouching(Run(2, 4:5), Run(0, 2:3))
    @test !istouching(Run(0, 5:6), Run(0, 1:2))
    @test !istouching(Run(0, 6:7), Run(0, 0:1))

    # isclose(a, b, dx, dy) — column distance ≤ dx AND row range distance ≤ dy
    @test !isclose(Run(0, 0:1), Run(0, 6:7), 0, 0)
    @test !isclose(Run(0, 1:2), Run(0, 5:6), 0, 0)
    @test !isclose(Run(0, 2:3), Run(0, 4:5), 0, 0)
    @test !isclose(Run(-1, 2:3), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 2:3), Run(-1, 3:4), 0, 0)
    @test  isclose(Run(0, 2:3), Run(0, 3:4), 0, 0)
    @test !isclose(Run(1, 2:3), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 2:3), Run(1, 3:4), 0, 0)
    @test !isclose(Run(-1, 3:4), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 3:4), Run(-1, 3:4), 0, 0)
    @test  isclose(Run(0, 3:4), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 3:4), Run(1, 3:4), 0, 0)
    @test !isclose(Run(1, 3:4), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 4:5), Run(0, 2:3), 0, 0)
    @test !isclose(Run(0, 5:6), Run(0, 1:2), 0, 0)
    @test !isclose(Run(0, 6:7), Run(0, 0:1), 0, 0)

    @test !isclose(Run(0, 0:1), Run(0, 6:7), 1, 1)
    @test !isclose(Run(0, 1:2), Run(0, 5:6), 1, 1)
    @test !isclose(Run(0, 2:3), Run(2, 4:5), 1, 1)
    @test  isclose(Run(0, 2:3), Run(-1, 4:5), 1, 1)
    @test  isclose(Run(0, 2:3), Run(1, 4:5), 1, 1)
    @test  isclose(Run(0, 2:3), Run(0, 4:5), 1, 1)
    @test  isclose(Run(1, 2:3), Run(0, 4:5), 1, 1)
    @test  isclose(Run(-1, 2:3), Run(0, 4:5), 1, 1)
    @test !isclose(Run(2, 2:3), Run(0, 4:5), 1, 1)
    @test !isclose(Run(-2, 2:3), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 2:3), Run(-2, 3:4), 1, 1)
    @test  isclose(Run(-1, 2:3), Run(0, 3:4), 1, 1)
    @test  isclose(Run(0, 2:3), Run(-1, 3:4), 1, 1)
    @test  isclose(Run(0, 2:3), Run(0, 3:4), 1, 1)
    @test  isclose(Run(0, 2:3), Run(1, 3:4), 1, 1)
    @test  isclose(Run(1, 2:3), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 2:3), Run(2, 3:4), 1, 1)
    @test !isclose(Run(2, 2:3), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 3:4), Run(-2, 3:4), 1, 1)
    @test !isclose(Run(-2, 3:4), Run(0, 3:4), 1, 1)
    @test  isclose(Run(0, 3:4), Run(-1, 3:4), 1, 1)
    @test  isclose(Run(-1, 3:4), Run(0, 3:4), 1, 1)
    @test  isclose(Run(0, 3:4), Run(0, 3:4), 1, 1)
    @test  isclose(Run(0, 3:4), Run(1, 3:4), 1, 1)
    @test  isclose(Run(1, 3:4), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 3:4), Run(2, 3:4), 1, 1)
    @test !isclose(Run(2, 3:4), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 4:5), Run(-2, 2:3), 1, 1)
    @test !isclose(Run(-2, 4:5), Run(0, 2:3), 1, 1)
    @test  isclose(Run(0, 4:5), Run(-1, 2:3), 1, 1)
    @test  isclose(Run(-1, 4:5), Run(0, 2:3), 1, 1)
    @test  isclose(Run(0, 4:5), Run(0, 2:3), 1, 1)
    @test  isclose(Run(0, 4:5), Run(1, 2:3), 1, 1)
    @test  isclose(Run(1, 4:5), Run(0, 2:3), 1, 1)
    @test !isclose(Run(0, 4:5), Run(2, 2:3), 1, 1)
    @test !isclose(Run(2, 4:5), Run(0, 2:3), 1, 1)
    @test !isclose(Run(0, 5:6), Run(0, 1:2), 1, 1)
    @test !isclose(Run(0, 6:7), Run(0, 0:1), 1, 1)

end # "Run"
