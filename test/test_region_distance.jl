@testset "Region Distance Transform" begin

    @testset "single pixel" begin
        d = distance_transform(Region([Run(0, 0:0)]))
        @test size(d) == (1, 1)
        @test d == reshape([1], 1, 1)
    end

    @testset "3×3 square" begin
        d = distance_transform(region_from_box(0, 0, 2, 2))
        @test d == [1 1 1;
                    1 2 1;
                    1 1 1]
    end

    @testset "5×5 square" begin
        d = distance_transform(region_from_box(0, 0, 4, 4))
        # The center is 3 steps from the nearest background pixel; symmetric
        # rings of 2 and 1 surround it.
        @test d == [1 1 1 1 1;
                    1 2 2 2 1;
                    1 2 3 2 1;
                    1 2 2 2 1;
                    1 1 1 1 1]
    end

    @testset "horizontal 1×N line" begin
        line = Region([Run(c, 0:0) for c in 0:4])   # 1 row × 5 cols
        d = distance_transform(line)
        @test size(d) == (1, 5)
        @test all(==(1), d)
    end

    @testset "vertical N×1 line" begin
        col = Region([Run(0, 0:4)])   # 5 rows × 1 col
        d = distance_transform(col)
        @test size(d) == (5, 1)
        @test all(==(1), d)
    end

    @testset "3×10 thin rectangle (fiber-like)" begin
        r = region_from_box(0, 0, 9, 2)   # 10 cols × 3 rows
        d = distance_transform(r)
        @test size(d) == (3, 10)
        # Top and bottom rows: every pixel borders background → all 1
        @test all(==(1), d[1, :])
        @test all(==(1), d[3, :])
        # Middle row: end pixels border background (left/right edge) → 1,
        # interior pixels are 2 away from top/bottom background
        @test d[2, 1] == 1
        @test d[2, end] == 1
        @test all(==(2), d[2, 2:end-1])
        @test maximum(d) == 2
    end

    @testset "translation invariance" begin
        r1 = region_from_box(0, 0, 4, 4)
        r2 = translate(r1, 100, -50)
        @test distance_transform(r1) == distance_transform(r2)
    end

    @testset "L-shape (non-convex)" begin
        # An L:
        #   col 0..2 cover rows 0..2 (3×3 block on the left)
        #   col 3..4 cover row 2 only (extension to the right along the bottom row)
        r = Region(vcat(
            [Run(c, 0:2) for c in 0:2],
            [Run(c, 2:2) for c in 3:4],
        ))
        d = distance_transform(r)
        # Bounding box: cols 0..4, rows 0..2 → 3 rows × 5 cols
        @test size(d) == (3, 5)
        # Manually computed DT for this L (background = 0 outside region):
        #   row 0:  1 1 1 0 0
        #   row 1:  1 2 1 0 0
        #   row 2:  1 1 1 1 1
        @test d == [1 1 1 0 0;
                    1 2 1 0 0;
                    1 1 1 1 1]
    end

    @testset "validation" begin
        @test_throws AssertionError distance_transform(Region(Run[]))
        @test_throws AssertionError distance_transform(complement(region_from_box(0, 0, 2, 2)))
    end

end # "Region Distance Transform"
