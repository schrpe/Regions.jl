using Regions
using Test

@testset "Regions" begin

    @testset "Range" begin
        @test (0:-1).start == 0
        @test (0:-1).stop == -1
        @test length(0:-1) == 0
        @test isempty(0:-1)

        @test (0:0).start == 0
        @test (0:0).stop == 0
        @test length(0:0) == 1
        @test !isempty(0:0)

        @test (0:1).start == 0
        @test (0:1).stop == 1
        @test length(0:1) == 2
        @test !isempty(0:1)

        @test 0:1 == 0:1
        @test 0:1 ≠ 1:2

        @test 0:1 ≤ 0:1
       
        @test 0:1 < 1:2
        @test 0:1 ≤ 1:2
        @test 0:1 ≤ 0:1

        @test 0:1 ≥ 0:1
       
        @test 1:2 > 0:1
        @test 1:2 ≥ 0:1
        @test 0:1 ≥ 0:1

        @test translate(1:2, -5) == -4:-3
        @test translate(1:2, 5) == 6:7
        @test (1:2) - 5 == -4:-3
        @test (1:2) + 5 == 6:7

        @test invert(1:2) == -2:-1
        @test invert(-1:0) == 0:1
        @test invert(invert(1:2)) == 1:2

        @test !contains(0:-1, 0)
        @test !contains(0:0, -1)
        @test contains(0:0, 0)
        @test !contains(0:0, 1)
        @test !contains(0:1, -1)
        @test contains(0:1, 0)
        @test contains(0:1, 1)
        @test !contains(0:1, 2)

        @test !isoverlapping(0:1, 6:7)
        @test !isoverlapping(1:2, 5:6)
        @test !isoverlapping(2:3, 4:5)
        @test isoverlapping(2:3, 3:4)
        @test isoverlapping(3:4, 3:4)
        @test !isoverlapping(4:5, 2:3)
        @test !isoverlapping(5:6, 1:2)
        @test !isoverlapping(6:7, 0:1)

        @test !istouching(0:1, 6:7)
        @test !istouching(1:2, 5:6)
        @test istouching(2:3, 4:5)
        @test istouching(2:3, 3:4)
        @test istouching(3:4, 3:4)
        @test istouching(4:5, 2:3)
        @test !istouching(5:6, 1:2)
        @test !istouching(6:7, 0:1)

        @test !isclose(0:1, 6:7, 0)
        @test !isclose(1:2, 5:6, 0)
        @test !isclose(2:3, 4:5, 0)
        @test isclose(2:3, 3:4, 0)
        @test isclose(3:4, 3:4, 0)
        @test !isclose(4:5, 2:3, 0)
        @test !isclose(5:6, 1:2, 0)
        @test !isclose(6:7, 0:1, 0)

        @test !isclose(0:1, 6:7, 1)
        @test !isclose(1:2, 5:6, 1)
        @test isclose(2:3, 4:5, 1)
        @test isclose(2:3, 3:4, 1)
        @test isclose(3:4, 3:4, 1)
        @test isclose(4:5, 2:3, 1)
        @test !isclose(5:6, 1:2, 1)
        @test !isclose(6:7, 0:1, 1)


        @test !isclose(0:1, 6:7, 3)
        @test isclose(1:2, 5:6, 3)
        @test isclose(2:3, 4:5, 3)
        @test isclose(2:3, 3:4, 3)
        @test isclose(3:4, 3:4, 3)
        @test isclose(4:5, 2:3, 3)
        @test isclose(5:6, 1:2, 3)
        @test !isclose(6:7, 0:1, 3)
    end # "Range"

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

    @testset "Region" begin
        @test length(Region(Run[]).runs) == 0

        @test Region([Run(0, 0:0)]).complement == false
        @test Region([Run(0, 0:0)], false).complement == false
        @test Region([Run(0, 0:0)], true).complement == true


        @test length(Region([Run(0, 0:0)]).runs) == 1
        @test Region([Run(0, 0:0)]).runs[1].row == 0
        @test Region([Run(0, 0:0)]).runs[1].columns.start == 0
        @test Region([Run(0, 0:0)]).runs[1].columns.stop == 0

        @test length(Region([Run(1, 2:3)]).runs) == 1
        @test Region([Run(1, 2:3)]).runs[1].row == 1
        @test Region([Run(1, 2:3)]).runs[1].columns.start == 2
        @test Region([Run(1, 2:3)]).runs[1].columns.stop == 3

        @test Region([Run(0, 0:0)], false) == Region([Run(0, 0:0)], false)
        @test Region([Run(0, 0:0)], true) == Region([Run(0, 0:0)], true)
        @test Region([Run(0, 0:0)], false) != Region([Run(0, 0:0)], true)
        @test Region([Run(0, 0:0)], true) != Region([Run(0, 0:0)], false)
        @test Region([Run(0, 0:0)], false) != Region([Run(1, 2:3)], true)

        @test Region([Run(0, 0:0)], false) == copy(Region([Run(0, 0:0)], false))

        @test invert(Region([Run(0, 0:0)])).runs[1].row == 0
        @test invert(Region([Run(0, 0:0)])).runs[1].columns.start == 0
        @test invert(Region([Run(0, 0:0)])).runs[1].columns.stop == 0
        @test invert(Region([Run(1, 2:3)])).runs[1].row == -1
        @test invert(Region([Run(1, 2:3)])).runs[1].columns.start == -3
        @test invert(Region([Run(1, 2:3)])).runs[1].columns.stop == -2
        @test invert(invert(Region([Run(1, 2:3)]))).runs[1].row == 1
        @test invert(invert(Region([Run(1, 2:3)]))).runs[1].columns.start == 2
        @test invert(invert(Region([Run(1, 2:3)]))).runs[1].columns.stop == 3
        @test (-Region([Run(1, 2:3)])).runs[1].row == -1
        @test (-Region([Run(1, 2:3)])).runs[1].columns.start == -3
        @test (-Region([Run(1, 2:3)])).runs[1].columns.stop == -2
        @test (- -Region([Run(1, 2:3)])).runs[1].row == 1
        @test (- -Region([Run(1, 2:3)])).runs[1].columns.start == 2
        @test (- -Region([Run(1, 2:3)])).runs[1].columns.stop == 3

        @test translate(Region([Run(1, 1:2), Run(2, 3:4)]), [-5, -6]) == Region([Run(-5, -4:-3), Run(-4, -2:-1)])
        @test Region([Run(1, 1:2), Run(2, 3:4)]) - [5, 6] == Region([Run(-5, -4:-3), Run(-4, -2:-1)])
        @test Region([Run(1, 1:2), Run(2, 3:4)]) + [5, 6] == Region([Run(7, 6:7), Run(8, 8:9)])
       
        @test !contains(Region([Run(0, 0:-1)]), 0, -1)
        @test !contains(Region([Run(0, 0:-1)]), 0, 0)
        @test !contains(Region([Run(0, 0:-1)]), 0, 1)
        @test !contains(Region([Run(0, 0:0)]), -1, -1)
        @test !contains(Region([Run(0, 0:0)]), 0, -1)
        @test !contains(Region([Run(0, 0:0)]), -1, 0)
        @test contains(Region([Run(0, 0:0)]), 0, 0)
        @test !contains(Region([Run(0, 0:0)]), 0, 1)
        @test !contains(Region([Run(0, 0:0)]), 1, 0)
        @test !contains(Region([Run(0, 0:1)]), -1, 0)
        @test !contains(Region([Run(0, 0:1)]), 0, -1)
        @test contains(Region([Run(0, 0:1)]), 0, 0)
        @test contains(Region([Run(0, 0:1)]), 1, 0)
        @test !contains(Region([Run(0, 0:1)]), 2, 0)
        @test !contains(Region([Run(0, 0:1)]), 1, 1)
        @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 0, 0)
        @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 1, 0)
        @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 0, 1)
        @test contains(Region([Run(0, 0:1), Run(1, 0:1)]), 1, 1)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 0)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), 2, 0)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 1)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), 2, 1)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 0)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 1)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 2)
        @test !contains(Region([Run(0, 0:1), Run(1, 0:1)]), -1, 2)

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

end
