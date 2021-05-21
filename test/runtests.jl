# This is the unit test suite for the Regions.jl package.

using Regions
using Test

@testset "Regions" begin

    include("test_range.jl")
    include("test_run.jl")
    include("test_region.jl")

end
