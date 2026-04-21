@testset "PointList" begin

    sq = [(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)]   # unit square

    @testset "centroid" begin
        @test centroid([(1.0,1.0)]) == (1.0, 1.0)
        @test centroid(sq) == (0.5, 0.5)
        @test centroid([(0.0,0.0),(2.0,0.0),(2.0,2.0),(0.0,2.0)]) == (1.0, 1.0)
    end

    @testset "bounding_box" begin
        bb = bounding_box([(1.0,2.0),(3.0,4.0),(2.0,1.0)])
        @test bb.xmin == 1.0 && bb.xmax == 3.0
        @test bb.ymin == 1.0 && bb.ymax == 4.0
        bb2 = bounding_box(sq)
        @test bb2.xmin == 0.0 && bb2.xmax == 1.0
        @test bb2.ymin == 0.0 && bb2.ymax == 1.0
    end

    @testset "convex_hull" begin
        # Interior point should not appear in hull
        pts = [sq; [(0.5,0.5)]]
        h = convex_hull(pts)
        @test length(h) == 4
        @test all(v in h for v in sq)
        @test !((0.5,0.5) in h)
        # Single point
        @test convex_hull([(3.0,4.0)]) == [(3.0,4.0)]
    end

    @testset "convex_hull_cw" begin
        @test convex_hull_cw(sq) == reverse(convex_hull(sq))
    end

    @testset "remove_collinear" begin
        # Midpoint on bottom edge is collinear
        pts = [(0.0,0.0),(0.5,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)]
        result = remove_collinear(pts)
        @test length(result) == 4
        @test !((0.5,0.0) in result)
        # No collinear vertices: unchanged
        @test remove_collinear(sq) == sq
        # Less than 3 points: unchanged
        @test remove_collinear([(1.0,2.0),(3.0,4.0)]) == [(1.0,2.0),(3.0,4.0)]
    end

    @testset "feret_diameters" begin
        mn, mx = feret_diameters(sq)
        @test mn ≈ 1.0
        @test mx ≈ sqrt(2)
        # Degenerate: two points
        mn2, mx2 = feret_diameters([(0.0,0.0),(3.0,4.0)])
        @test mn2 ≈ 5.0 && mx2 ≈ 5.0
    end

    @testset "minimum_width / maximum_width" begin
        @test minimum_width(sq) ≈ 1.0
        @test maximum_width(sq) ≈ sqrt(2)
    end

    @testset "minimum_area_bounding_rectangle" begin
        r = minimum_area_bounding_rectangle([(0.0,0.0),(2.0,0.0),(2.0,1.0),(0.0,1.0)])
        @test r.area ≈ 2.0
        @test length(r.corners) == 4
        # Unit square: area = 1
        @test minimum_area_bounding_rectangle(sq).area ≈ 1.0
    end

    @testset "minimum_perimeter_bounding_rectangle" begin
        r = minimum_perimeter_bounding_rectangle([(0.0,0.0),(2.0,0.0),(2.0,1.0),(0.0,1.0)])
        @test r.perimeter ≈ 6.0
        @test length(r.corners) == 4
    end

    @testset "minimum_bounding_circle" begin
        # 2×2 square: center (1,1), radius sqrt(2)
        c = minimum_bounding_circle([(0.0,0.0),(2.0,0.0),(2.0,2.0),(0.0,2.0)])
        @test c.center[1] ≈ 1.0
        @test c.center[2] ≈ 1.0
        @test c.radius ≈ sqrt(2)
        # Single point
        c1 = minimum_bounding_circle([(3.0,4.0)])
        @test c1.center == (3.0, 4.0) && c1.radius == 0.0
        # Two points
        c2 = minimum_bounding_circle([(0.0,0.0),(4.0,0.0)])
        @test c2.center[1] ≈ 2.0 && c2.center[2] ≈ 0.0
        @test c2.radius ≈ 2.0
    end

    @testset "translate" begin
        t = translate(sq, 3.0, 4.0)
        @test t == [(3.0,4.0),(4.0,4.0),(4.0,5.0),(3.0,5.0)]
        t2 = translate(sq, [1, 2])
        @test t2 == [(1.0,2.0),(2.0,2.0),(2.0,3.0),(1.0,3.0)]
    end

end
