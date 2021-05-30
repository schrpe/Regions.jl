# Unit tests for Region type.
# This file is supposed to be included from runtests.jl.

@testset "Region" begin
    @test length(Region().runs) == 0
    @test length(Region(Run[]).runs) == 0
    @test length(Region(Run[], false).runs) == 0

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
    @test [1, 0] ∈ Region([Run(0, 0:1)])
    @test [2, 0] ∉ Region([Run(0, 0:1)])
    @test [1, 1] ∉ Region([Run(0, 0:1)])
    @test [0, 0] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [1, 0] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [0, 1] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [1, 1] ∈ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 0] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [2, 0] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 1] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [2, 1] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 0] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 1] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 2] ∉ Region([Run(0, 0:1), Run(1, 0:1)])
    @test [-1, 2] ∉ Region([Run(0, 0:1), Run(1, 0:1)])

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
