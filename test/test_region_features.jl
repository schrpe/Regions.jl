@testset "Region Features" begin

    # ── Phase A: Basic Geometry ───────────────────────────────────────────────

    @testset "area" begin
        @test area(Region(Run[])) == 0
        @test area(Region([Run(2, 3:3)])) == 1
        @test area(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)])) == 9
    end

    @testset "width" begin
        @test width(Region([Run(0, 0:0)])) == 1
        @test width(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)])) == 3
        @test width(Region([Run(-2, 0:0), Run(3, 0:0)])) == 6
    end

    @testset "height" begin
        @test height(Region([Run(0, 0:0)])) == 1
        @test height(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)])) == 3
        @test height(Region([Run(0, -2:3)])) == 6
    end

    @testset "bounds_center" begin
        @test bounds_center(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)])) == (1.0, 0.0)
        @test bounds_center(Region([Run(0, 0:1), Run(1, 0:1)])) == (0.5, 0.5)
    end

    @testset "aspect_ratio" begin
        @test aspect_ratio(Region([Run(0, 0:3), Run(1, 0:3)])) ≈ 0.5
        @test aspect_ratio(Region([Run(0, 0:0), Run(1, 0:0), Run(2, 0:0)])) ≈ 3.0
    end

    # ── Phase B: Moments ─────────────────────────────────────────────────────

    @testset "moments - single pixel" begin
        m = moments(Region([Run(2, 3:3)]))
        @test m.m00 ≈ 1.0
        @test m.m10 ≈ 2.0
        @test m.m01 ≈ 3.0
        @test m.m20 ≈ 4.0
        @test m.m11 ≈ 6.0
        @test m.m02 ≈ 9.0
        @test m.m30 ≈ 8.0
        @test m.m21 ≈ 12.0
        @test m.m12 ≈ 18.0
        @test m.m03 ≈ 27.0
    end

    @testset "moments - 3×3 box at origin" begin
        r = Region([Run(c, -1:1) for c in -1:1])
        m = moments(r)
        @test m.m00 ≈ 9.0
        @test m.m10 ≈ 0.0   # symmetric around x=0
        @test m.m01 ≈ 0.0   # symmetric around y=0
        @test m.m11 ≈ 0.0   # symmetric
    end

    @testset "moments - negative rows" begin
        r = Region([Run(0, -2:-1)])
        m = moments(r)
        @test m.m00 ≈ 2.0
        @test m.m01 ≈ -3.0   # (-2 + -1) = -3
        @test m.m02 ≈ 5.0    # (-2)² + (-1)² = 4 + 1
    end

    @testset "centroid" begin
        @test centroid(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)])) == (1.0, 0.0)
        @test centroid(Region([Run(2, 3:3)])) == (2.0, 3.0)
    end

    @testset "equivalent_ellipse" begin
        r3x3 = Region([Run(c, -1:1) for c in -1:1])
        e = equivalent_ellipse(r3x3)
        @test e.center == (0.0, 0.0)
        @test e.semi_axes[1] ≈ e.semi_axes[2]  # square → circle
        @test e.angle ≈ 0.0

        # Horizontal bar: wider than tall → major axis along column direction
        rbar = Region([Run(c, 0:0) for c in -4:4])
        ebar = equivalent_ellipse(rbar)
        @test ebar.semi_axes[1] > ebar.semi_axes[2]
    end

    # ── Phase C: Perimeter ────────────────────────────────────────────────────

    @testset "perimeter" begin
        @test perimeter(Region(Run[])) == 0.0
        @test perimeter(Region([Run(0, 0:0)])) == 4.0         # single pixel
        @test perimeter(Region([Run(0, 0:1), Run(1, 0:1)])) == 8.0   # 2×2 box
        @test perimeter(Region([Run(c, 0:2) for c in 0:2])) == 12.0  # 3×3 box
    end

    @testset "compactness" begin
        # 4-connected edge perimeter overestimates geometric perimeter,
        # so compactness > 1 even for circles — but it is a useful relative metric.
        rc = region_from_circle(0, 0, 50)
        rbar = Region([Run(c, 0:0) for c in 0:99])
        # A circle should be more compact (lower value) than a thin bar.
        @test compactness(rc) < compactness(rbar)
    end

    # ── Phase D: Convex Hull ─────────────────────────────────────────────────

    @testset "convex_hull" begin
        r = Region([Run(0, 0:1), Run(1, 0:1)])
        h = convex_hull(r)
        @test length(h) == 4
    end

    @testset "convex_area" begin
        # 2×2 box: convex_area should equal area (it's already convex)
        r = Region([Run(0, 0:1), Run(1, 0:1)])
        @test convex_area(r) ≈ 4.0
        @test convex_area(r) ≈ Float64(area(r))

        # 5×5 box
        r5 = Region([Run(c, 0:4) for c in 0:4])
        @test convex_area(r5) ≈ 25.0

        # Larger circle: convex_area ≈ area (circle is convex)
        rc = region_from_circle(0, 0, 30)
        @test convex_area(rc) / area(rc) > 0.999
    end

    @testset "convex_perimeter" begin
        r = Region([Run(0, 0:1), Run(1, 0:1)])
        @test convex_perimeter(r) ≈ 8.0
    end

    @testset "convexity" begin
        r = Region([Run(0, 0:1), Run(1, 0:1)])
        @test convexity(r) ≈ 1.0
    end

    @testset "perforation" begin
        r = Region([Run(0, 0:1), Run(1, 0:1)])
        @test perforation(r) ≈ 0.0
    end

    @testset "feret_diameters" begin
        mn, mx = feret_diameters(Region([Run(0, 0:0)]))
        # Half-integer corners: pixel square diagonal = sqrt(2)
        @test mn ≈ 1.0
        @test mx ≈ sqrt(2)

        # Square: min feret = side length, max feret = diagonal
        r4 = Region([Run(c, 0:3) for c in 0:3])
        mn4, mx4 = feret_diameters(r4)
        @test mn4 ≈ 4.0 atol=0.01
        @test mx4 ≈ 4.0 * sqrt(2) atol=0.01
    end

    # ── Phase E: Boundary Polygons ───────────────────────────────────────────

    @testset "vectorized_boundaries and contour" begin
        # Single pixel → one polygon with 4 corners
        polys = vectorized_boundaries(Region([Run(0, 0:0)]))
        @test length(polys) == 1
        @test length(polys[1]) == 4
        # All four half-integer corners present
        pts = Set(polys[1])
        @test (-0.5,-0.5) in pts
        @test ( 0.5,-0.5) in pts
        @test ( 0.5, 0.5) in pts
        @test (-0.5, 0.5) in pts

        # 2×2 square → one polygon, 6 points (collinear midpoints on each long side)
        sq = Region([Run(0, 0:1), Run(1, 0:1)])
        polys2 = vectorized_boundaries(sq)
        @test length(polys2) == 1
        @test length(polys2[1]) == 6  # 4 corners + 2 collinear midpoints

        # Frame with hole → two polygons
        frame = difference(region_from_box(-2, -2, 2, 2), region_from_box(-1, -1, 1, 1))
        pf = vectorized_boundaries(frame)
        @test length(pf) == 2

        # Empty region → no polygons
        @test isempty(vectorized_boundaries(Region(Run[])))

        # contour returns first boundary
        @test contour(Region([Run(0, 0:0)])) == vectorized_boundaries(Region([Run(0, 0:0)]))[1]
    end

    @testset "to_point_list" begin
        # Single pixel → 4 points
        @test length(to_point_list(Region([Run(0, 0:0)]))) == 4
        # to_point_list is the concatenation of vectorized_boundaries
        r = Region([Run(c, 0:2) for c in 0:2])
        @test length(to_point_list(r)) == sum(length(p) for p in vectorized_boundaries(r))
    end

    # ── Phase F: Hole Features ────────────────────────────────────────────────

    @testset "number_of_holes and area_of_holes" begin
        # Solid square: no holes
        r = Region([Run(c, 0:4) for c in 0:4])
        @test number_of_holes(r) == 0
        @test area_of_holes(r) == 0

        # Ring: 1 hole
        ring_cols = [Run(c, 0:4) for c in 0:4]
        # Remove interior (column 1-3, rows 1-3)
        ring_full = Region([Run(c, 0:4) for c in 0:4])
        # Manually build a ring: 5 full rows but hollow middle
        ring = Region(vcat(
            [Run(0, 0:4)],
            [Run(1, 0:0), Run(1, 4:4)],
            [Run(2, 0:0), Run(2, 4:4)],
            [Run(3, 0:0), Run(3, 4:4)],
            [Run(4, 0:4)]
        ))
        @test number_of_holes(ring) == 1
        @test area_of_holes(ring) == 9
    end

    # ── Phase 1: Region adapters for bounding geometries ─────────────────────

    @testset "minimum_bounding_circle(::Region)" begin
        r = region_from_box(0, 0, 4, 4)   # 5×5 pixel square, corners at (-0.5,-0.5)..(4.5,4.5)
        c = minimum_bounding_circle(r)
        # Circumcircle: center at bounding-box centre, radius = half-diagonal of the
        # half-integer corner box (side 5 → diagonal √50 → radius 2.5·√2)
        @test c.center[1] ≈ 2.0
        @test c.center[2] ≈ 2.0
        @test c.radius ≈ 2.5 * sqrt(2)
    end

    @testset "minimum_area_bounding_rectangle(::Region)" begin
        r = region_from_box(0, 0, 4, 2)   # 5 wide × 3 tall
        rect = minimum_area_bounding_rectangle(r)
        @test rect.area ≈ 5.0 * 3.0
        # Width and height match the box dimensions (any orientation)
        @test sort([rect.width, rect.height]) ≈ [3.0, 5.0]
    end

    @testset "minimum_perimeter_bounding_rectangle(::Region)" begin
        r = region_from_box(0, 0, 4, 2)
        rect = minimum_perimeter_bounding_rectangle(r)
        @test rect.perimeter ≈ 2 * (5.0 + 3.0)
        @test sort([rect.width, rect.height]) ≈ [3.0, 5.0]
    end

end
