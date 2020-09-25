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

        @test Regions.transpose(1:2) == -1:0
        @test Regions.transpose(-1:0) == 1:2
        @test Regions.transpose(Regions.transpose(1:2)) == 1:2

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


    end # "Run"



end
