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
