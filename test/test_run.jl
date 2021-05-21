# Unit tests for Run type.
# This file is supposed to be included from runtests.jl.

@testset "Run" begin
    @test Run(0, 0:0).row == 0
    @test Run(0, 0:0).columns.start == 0
    @test Run(0, 0:0).columns.stop == 0

    @test Run(0, 0:-1).columns == 0:-1
    @test Run(0, 0:-1).columns.start == 0
    @test Run(0, 0:-1).columns.stop == -1
    @test length(Run(0, 0:-1).columns) == 0
    @test isempty(Run(0, 0:-1).columns)

    @test Run(0, 0:0).columns == 0:0
    @test Run(0, 0:0).columns.start == 0
    @test Run(0, 0:0).columns.stop == 0
    @test length(Run(0, 0:0).columns) == 1
    @test !isempty(Run(0, 0:0).columns)

    @test Run(0, 0:1).columns == 0:1
    @test Run(0, 0:1).columns.start == 0
    @test Run(0, 0:1).columns.stop == 1
    @test length(Run(0, 0:1).columns) == 2
    @test !isempty(Run(0, 0:1).columns)

    @test Run(0, 0:1) == Run(0, 0:1)
    @test Run(0, 0:1) ≠ Run(1, 0:1)
    @test Run(0, 0:1) ≠ Run(0, 1:2)

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

    @test translate(Run(1, 1:2), [-5, -6]) == Run(-5, -4:-3)
    @test translate(Run(1, 1:2), [5, 6]) == Run(7, 6:7)
    @test Run(1, 1:2) - [5, 6] == Run(-5, -4:-3)
    @test Run(1, 1:2) + [5, 6] == Run(7, 6:7)

    @test -Run(1, 1:2) == Run(-1, -2:-1)
    @test -Run(-1, -1:0) == Run(1, 0:1)
    @test -(-(Run(1, 1:2))) == Run(1, 1:2)

    @test invert(Run(1, 1:2)) == Run(-1, -2:-1)
    @test invert(Run(-1, -1:0)) == Run(1, 0:1)
    @test invert(invert(Run(1, 1:2))) == Run(1, 1:2)

    @test !contains(Run(0, 0:-1), 0, -1)
    @test !contains(Run(0, 0:-1), 0, 0)
    @test !contains(Run(0, 0:-1), 0, 1)
    @test !contains(Run(0, 0:0), -1, -1)
    @test !contains(Run(0, 0:0), 0, -1)
    @test !contains(Run(0, 0:0), -1, 0)
    @test contains(Run(0, 0:0), 0, 0)
    @test !contains(Run(0, 0:0), 0, 1)
    @test !contains(Run(0, 0:0), 1, 0)
    @test !contains(Run(0, 0:1), -1, 0)
    @test !contains(Run(0, 0:1), 0, -1)
    @test contains(Run(0, 0:1), 0, 0)
    @test contains(Run(0, 0:1), 1, 0)
    @test !contains(Run(0, 0:1), 2, 0)
    @test !contains(Run(0, 0:1), 1, 1)

    @test !isoverlapping(Run(0, 0:1), Run(0, 6:7))
    @test !isoverlapping(Run(0, 1:2), Run(0, 5:6))
    @test !isoverlapping(Run(0, 2:3), Run(0, 4:5))
    @test !isoverlapping(Run(-1, 2:3), Run(0, 3:4))
    @test !isoverlapping(Run(0, 2:3), Run(-1, 3:4))
    @test isoverlapping(Run(0, 2:3), Run(0, 3:4))
    @test !isoverlapping(Run(1, 2:3), Run(0, 3:4))
    @test !isoverlapping(Run(0, 2:3), Run(1, 3:4))
    @test !isoverlapping(Run(-1, 3:4), Run(0, 3:4))
    @test !isoverlapping(Run(0, 3:4), Run(-1, 3:4))
    @test isoverlapping(Run(0, 3:4), Run(0, 3:4))
    @test !isoverlapping(Run(0, 3:4), Run(1, 3:4))
    @test !isoverlapping(Run(1, 3:4), Run(0, 3:4))
    @test !isoverlapping(Run(0, 4:5), Run(0, 2:3))
    @test !isoverlapping(Run(0, 5:6), Run(0, 1:2))
    @test !isoverlapping(Run(0, 6:7), Run(0, 0:1))

    @test !istouching(Run(0, 0:1), Run(0, 6:7))
    @test !istouching(Run(0, 1:2), Run(0, 5:6))
    @test !istouching(Run(0, 2:3), Run(2, 4:5))
    @test istouching(Run(0, 2:3), Run(-1, 4:5))
    @test istouching(Run(0, 2:3), Run(1, 4:5))
    @test istouching(Run(0, 2:3), Run(0, 4:5))
    @test istouching(Run(1, 2:3), Run(0, 4:5))
    @test istouching(Run(-1, 2:3), Run(0, 4:5))
    @test !istouching(Run(2, 2:3), Run(0, 4:5))
    @test !istouching(Run(-2, 2:3), Run(0, 3:4))
    @test !istouching(Run(0, 2:3), Run(-2, 3:4))
    @test istouching(Run(-1, 2:3), Run(0, 3:4))
    @test istouching(Run(0, 2:3), Run(-1, 3:4))
    @test istouching(Run(0, 2:3), Run(0, 3:4))
    @test istouching(Run(0, 2:3), Run(1, 3:4))
    @test istouching(Run(1, 2:3), Run(0, 3:4))
    @test !istouching(Run(0, 2:3), Run(2, 3:4))
    @test !istouching(Run(2, 2:3), Run(0, 3:4))
    @test !istouching(Run(0, 3:4), Run(-2, 3:4))
    @test !istouching(Run(-2, 3:4), Run(0, 3:4))
    @test istouching(Run(0, 3:4), Run(-1, 3:4))
    @test istouching(Run(-1, 3:4), Run(0, 3:4))
    @test istouching(Run(0, 3:4), Run(0, 3:4))
    @test istouching(Run(0, 3:4), Run(1, 3:4))
    @test istouching(Run(1, 3:4), Run(0, 3:4))
    @test !istouching(Run(0, 3:4), Run(2, 3:4))
    @test !istouching(Run(2, 3:4), Run(0, 3:4))
    @test !istouching(Run(0, 4:5), Run(-2, 2:3))
    @test !istouching(Run(-2, 4:5), Run(0, 2:3))
    @test istouching(Run(0, 4:5), Run(-1, 2:3))
    @test istouching(Run(-1, 4:5), Run(0, 2:3))
    @test istouching(Run(0, 4:5), Run(0, 2:3))
    @test istouching(Run(0, 4:5), Run(1, 2:3))
    @test istouching(Run(1, 4:5), Run(0, 2:3))
    @test !istouching(Run(0, 4:5), Run(2, 2:3))
    @test !istouching(Run(2, 4:5), Run(0, 2:3))
    @test !istouching(Run(0, 5:6), Run(0, 1:2))
    @test !istouching(Run(0, 6:7), Run(0, 0:1))

    @test !isclose(Run(0, 0:1), Run(0, 6:7), 0, 0)
    @test !isclose(Run(0, 1:2), Run(0, 5:6), 0, 0)
    @test !isclose(Run(0, 2:3), Run(0, 4:5), 0, 0)
    @test !isclose(Run(-1, 2:3), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 2:3), Run(-1, 3:4), 0, 0)
    @test isclose(Run(0, 2:3), Run(0, 3:4), 0, 0)
    @test !isclose(Run(1, 2:3), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 2:3), Run(1, 3:4), 0, 0)
    @test !isclose(Run(-1, 3:4), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 3:4), Run(-1, 3:4), 0, 0)
    @test isclose(Run(0, 3:4), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 3:4), Run(1, 3:4), 0, 0)
    @test !isclose(Run(1, 3:4), Run(0, 3:4), 0, 0)
    @test !isclose(Run(0, 4:5), Run(0, 2:3), 0, 0)
    @test !isclose(Run(0, 5:6), Run(0, 1:2), 0, 0)
    @test !isclose(Run(0, 6:7), Run(0, 0:1), 0, 0)

    @test !isclose(Run(0, 0:1), Run(0, 6:7), 1, 1)
    @test !isclose(Run(0, 1:2), Run(0, 5:6), 1, 1)
    @test !isclose(Run(0, 2:3), Run(2, 4:5), 1, 1)
    @test isclose(Run(0, 2:3), Run(-1, 4:5), 1, 1)
    @test isclose(Run(0, 2:3), Run(1, 4:5), 1, 1)
    @test isclose(Run(0, 2:3), Run(0, 4:5), 1, 1)
    @test isclose(Run(1, 2:3), Run(0, 4:5), 1, 1)
    @test isclose(Run(-1, 2:3), Run(0, 4:5), 1, 1)
    @test !isclose(Run(2, 2:3), Run(0, 4:5), 1, 1)
    @test !isclose(Run(-2, 2:3), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 2:3), Run(-2, 3:4), 1, 1)
    @test isclose(Run(-1, 2:3), Run(0, 3:4), 1, 1)
    @test isclose(Run(0, 2:3), Run(-1, 3:4), 1, 1)
    @test isclose(Run(0, 2:3), Run(0, 3:4), 1, 1)
    @test isclose(Run(0, 2:3), Run(1, 3:4), 1, 1)
    @test isclose(Run(1, 2:3), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 2:3), Run(2, 3:4), 1, 1)
    @test !isclose(Run(2, 2:3), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 3:4), Run(-2, 3:4), 1, 1)
    @test !isclose(Run(-2, 3:4), Run(0, 3:4), 1, 1)
    @test isclose(Run(0, 3:4), Run(-1, 3:4), 1, 1)
    @test isclose(Run(-1, 3:4), Run(0, 3:4), 1, 1)
    @test isclose(Run(0, 3:4), Run(0, 3:4), 1, 1)
    @test isclose(Run(0, 3:4), Run(1, 3:4), 1, 1)
    @test isclose(Run(1, 3:4), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 3:4), Run(2, 3:4), 1, 1)
    @test !isclose(Run(2, 3:4), Run(0, 3:4), 1, 1)
    @test !isclose(Run(0, 4:5), Run(-2, 2:3), 1, 1)
    @test !isclose(Run(-2, 4:5), Run(0, 2:3), 1, 1)
    @test isclose(Run(0, 4:5), Run(-1, 2:3), 1, 1)
    @test isclose(Run(-1, 4:5), Run(0, 2:3), 1, 1)
    @test isclose(Run(0, 4:5), Run(0, 2:3), 1, 1)
    @test isclose(Run(0, 4:5), Run(1, 2:3), 1, 1)
    @test isclose(Run(1, 4:5), Run(0, 2:3), 1, 1)
    @test !isclose(Run(0, 4:5), Run(2, 2:3), 1, 1)
    @test !isclose(Run(2, 4:5), Run(0, 2:3), 1, 1)
    @test !isclose(Run(0, 5:6), Run(0, 1:2), 1, 1)
    @test !isclose(Run(0, 6:7), Run(0, 0:1), 1, 1)

end # "Run"
