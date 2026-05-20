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

    # ── Phase 2: Moments (central / normalized / Hu / Flusser) ───────────────

    @testset "central_moments" begin
        # 3×3 box centred at origin: μ11=0 (symmetry), μ30=μ03=0 (odd power × symmetric)
        r = Region([Run(c, -1:1) for c in -1:1])
        μ = central_moments(r)
        @test μ.μ11 ≈ 0.0
        @test μ.μ30 ≈ 0.0
        @test μ.μ03 ≈ 0.0
        @test μ.μ21 ≈ 0.0
        @test μ.μ12 ≈ 0.0
        # Σ x² over -1,0,1 = 2, times 3 rows = 6
        @test μ.μ20 ≈ 6.0
        @test μ.μ02 ≈ 6.0

        # Translation invariance: μ values do not change under translation
        r2 = translate(r, 100, -50)
        μ2 = central_moments(r2)
        @test μ.μ20 ≈ μ2.μ20
        @test μ.μ02 ≈ μ2.μ02
        @test μ.μ11 ≈ μ2.μ11
        @test μ.μ30 ≈ μ2.μ30
        @test μ.μ21 ≈ μ2.μ21
        @test μ.μ12 ≈ μ2.μ12
        @test μ.μ03 ≈ μ2.μ03
    end

    @testset "normalized_moments / scale_invariant_moments" begin
        # Scale invariance: a circle of radius 10 and radius 30 should have
        # almost identical normalized moments (some discretization noise)
        c1 = region_from_circle(0, 0, 10)
        c2 = region_from_circle(0, 0, 30)
        η1 = normalized_moments(c1)
        η2 = normalized_moments(c2)
        @test isapprox(η1.η20, η2.η20; atol=5e-3)
        @test isapprox(η1.η02, η2.η02; atol=5e-3)

        # Alias works
        @test scale_invariant_moments(c1) == normalized_moments(c1)
    end

    @testset "hu_moments" begin
        # Circle: I1 > 0, I2..I7 should all be ≈ 0 due to rotational symmetry
        c = region_from_circle(0, 0, 30)
        I = hu_moments(c)
        @test I[1] > 0
        @test abs(I[2]) < 1e-3
        @test abs(I[3]) < 1e-3
        @test abs(I[4]) < 1e-3
        @test abs(I[5]) < 1e-6
        @test abs(I[6]) < 1e-5
        @test abs(I[7]) < 1e-6

        # Translation invariance: Hu moments unchanged after translation
        c_translated = translate(c, 1000, -500)
        It = hu_moments(c_translated)
        for i in 1:7
            @test isapprox(I[i], It[i]; atol=1e-10)
        end

        # Scale invariance: circle at different scales has matching Hu moments
        c_small = region_from_circle(0, 0, 10)
        I_small = hu_moments(c_small)
        @test isapprox(I[1], I_small[1]; atol=1e-2)
    end

    @testset "flusser_moments" begin
        # Affine invariance: I1 should be the same after pure scaling
        c10 = region_from_circle(0, 0, 10)
        c30 = region_from_circle(0, 0, 30)
        F10 = flusser_moments(c10)
        F30 = flusser_moments(c30)
        @test F10[1] > 0
        @test isapprox(F10[1], F30[1]; atol=1e-3)

        # Translation invariance
        F_translated = flusser_moments(translate(c10, 1000, -500))
        for i in 1:4
            @test isapprox(F10[i], F_translated[i]; atol=1e-8)
        end
    end

    # ── Phase 3: Shape descriptors ───────────────────────────────────────────

    @testset "circularity" begin
        # In [0, 1] for any non-empty region
        circle = region_from_circle(0, 0, 50)
        @test 0 < circularity(circle) ≤ 1.0
        # Square is less circular than a disk (4-connected perimeter is similar
        # in absolute terms but area-to-perimeter favours the disk slightly)
        @test circularity(circle) > 0.7
        # Degenerate: single pixel -> 4-conn perim = 4, area = 1
        # circularity = 2*sqrt(π) / 4 ≈ 0.886
        @test circularity(Region([Run(0, 0:0)])) ≈ 2 * sqrt(π) / 4
    end

    @testset "sphericity" begin
        # Disk is highly spherical
        @test sphericity(region_from_circle(0, 0, 50)) > 0.95
        # Long thin bar is much less spherical
        bar = region_from_box(0, 0, 19, 1)
        @test sphericity(bar) < 0.5
    end

    @testset "roundness" begin
        @test 0 < roundness(region_from_circle(0, 0, 50)) ≤ 1.0
        @test roundness(region_from_circle(0, 0, 50)) > 0.9
        # A square fills only ~63 % of its bounding circle (π·r² where r = halfdiag)
        # 5×5 square area=25; bounding circle radius = 2.5·√2; π·r² = 6.25·2π = 39.27
        sq = region_from_box(0, 0, 4, 4)
        @test roundness(sq) ≈ 25.0 / (π * (2.5 * sqrt(2))^2)
    end

    @testset "roughness" begin
        # Convex region: perimeter == convex_perimeter for axis-aligned rectangles
        @test roughness(region_from_box(0, 0, 4, 4)) ≈ 1.0
        # Discretised circle has a longer 4-connected perimeter than its convex hull
        @test roughness(region_from_circle(0, 0, 50)) > 1.0
    end

    # ── Fiber metrics ────────────────────────────────────────────────────────

    @testset "fiber_length" begin
        # Single pixel: perimeter = 4 → fiber_length = 2.0
        @test fiber_length(Region([Run(0, 0:0)])) == 2.0
        # 3×3 box: perimeter = 12 → fiber_length = 6.0
        @test fiber_length(region_from_box(0, 0, 2, 2)) == 6.0
        # Identity: always exactly half the perimeter
        c = region_from_circle(0, 0, 17)
        @test fiber_length(c) == 0.5 * perimeter(c)
        # Translation invariance
        r = region_from_box(0, 0, 4, 2)
        @test fiber_length(translate(r, 100, -50)) == fiber_length(r)
    end

    @testset "fiber_width" begin
        # Single pixel: max DT = 1 → fiber_width = 2
        @test fiber_width(Region([Run(0, 0:0)])) == 2.0
        # 3×3 box: max DT = 2 → fiber_width = 4
        @test fiber_width(region_from_box(0, 0, 2, 2)) == 4.0
        # 5×5 box: max DT = 3 → fiber_width = 6
        @test fiber_width(region_from_box(0, 0, 4, 4)) == 6.0
        # 3×10 elongated rectangle: max DT = 2 (middle row) → fiber_width = 4
        @test fiber_width(region_from_box(0, 0, 9, 2)) == 4.0
        # Translation invariance
        r = region_from_box(0, 0, 4, 2)
        @test fiber_width(translate(r, 100, -50)) == fiber_width(r)
    end

end
