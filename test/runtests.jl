# This is the unit test suite for the Regions.jl package.

using Regions
using Test

@testset "Regions" begin

    include("test_range.jl")
    include("test_run.jl")
    include("test_region.jl")
    include("test_morphology.jl")
    include("test_point_list.jl")
    include("test_region_features.jl")

end
