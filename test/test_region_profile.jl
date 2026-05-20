@testset "Region Profiles" begin

    @testset "profile_horizontal — full-image region" begin
        img = Float64[1 2 3; 4 5 6; 7 8 9]
        r = region_from_box(1, 1, 3, 3)
        # Row sums: row 1 → 1+2+3=6, row 2 → 4+5+6=15, row 3 → 7+8+9=24
        @test profile_horizontal(r, img) == [6.0, 15.0, 24.0]
    end

    @testset "profile_vertical — full-image region" begin
        img = Float64[1 2 3; 4 5 6; 7 8 9]
        r = region_from_box(1, 1, 3, 3)
        # Column sums: col 1 → 1+4+7=12, col 2 → 2+5+8=15, col 3 → 3+6+9=18
        @test profile_vertical(r, img) == [12.0, 15.0, 18.0]
    end

    @testset "pixels outside region are not summed" begin
        # 4×4 image of ones; region covers only the upper-left 2×2 corner
        img = ones(Float64, 4, 4)
        r = region_from_box(1, 1, 2, 2)
        # Horizontal profile: 2 elements, each = 2 (two ones per row in region)
        @test profile_horizontal(r, img) == [2.0, 2.0]
        @test profile_vertical(r, img)   == [2.0, 2.0]
        # Total area equals sum of either profile
        @test sum(profile_horizontal(r, img)) == area(r)
        @test sum(profile_vertical(r, img))   == area(r)
    end

    @testset "non-rectangular region" begin
        # Cross shape inside a 3×3 image of value 10
        # ('-' = outside, '#' = inside)
        # row 1:  -  #  -
        # row 2:  #  #  #
        # row 3:  -  #  -
        img = fill(10.0, 3, 3)
        r = Region([Run(1, 2:2), Run(2, 1:3), Run(3, 2:2)])
        # Horizontal: row 1 → 10 (only middle), row 2 → 30 (all), row 3 → 10
        @test profile_horizontal(r, img) == [10.0, 30.0, 10.0]
        # Vertical: col 1 → 10, col 2 → 30, col 3 → 10
        @test profile_vertical(r, img) == [10.0, 30.0, 10.0]
    end

    @testset "asymmetric image — verifies row vs column axis" begin
        # row-index ≠ col-index image: catches axis confusion
        img = Float64[10 20 30 40; 50 60 70 80]
        r = region_from_box(1, 1, 4, 2)
        # H: row 1 → 10+20+30+40 = 100; row 2 → 50+60+70+80 = 260
        @test profile_horizontal(r, img) == [100.0, 260.0]
        # V: each column = upper + lower
        @test profile_vertical(r, img) == [60.0, 80.0, 100.0, 120.0]
    end

    @testset "integer pixel types accumulate in Int64 to avoid overflow" begin
        img = fill(UInt8(255), 4, 4)
        r = region_from_box(1, 1, 4, 4)
        ph = profile_horizontal(r, img)
        pv = profile_vertical(r, img)
        @test eltype(ph) === Int64
        @test eltype(pv) === Int64
        @test ph == fill(4 * 255, 4)
        @test pv == fill(4 * 255, 4)
        # Result fits in Int64 — would overflow UInt8/Int16 accumulator
        @test sum(ph) == 16 * 255
    end

    @testset "validation" begin
        img = zeros(Float64, 3, 3)
        # Empty region
        @test_throws AssertionError profile_horizontal(Region(Run[]), img)
        @test_throws AssertionError profile_vertical(Region(Run[]), img)
        # Complement region
        r = region_from_box(1, 1, 3, 3)
        @test_throws AssertionError profile_horizontal(complement(r), img)
        @test_throws AssertionError profile_vertical(complement(r), img)
        # Region with coordinates outside the image
        out = region_from_box(0, 0, 3, 3)   # left=0, top=0 → out of [1, 3]
        @test_throws AssertionError profile_horizontal(out, img)
        @test_throws AssertionError profile_vertical(out, img)
        out2 = region_from_box(1, 1, 5, 3)  # right=5 > 3 cols
        @test_throws AssertionError profile_horizontal(out2, img)
    end

end # "Region Profiles"
