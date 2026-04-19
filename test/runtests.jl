# This is the unit test suite for the Regions.jl package.

using Regions
using Test

@testset "Regions" begin

    include("test_range.jl")
    include("test_run.jl")
    include("test_region.jl")
    include("test_binarize.jl")
    include("test_region_vector.jl")
    include("test_complement.jl")
    include("test_region_from_box.jl")

end
