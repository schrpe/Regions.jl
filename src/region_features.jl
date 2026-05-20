#= ------------------------------------------------------------------------

    Region Features (Blob Analysis)

    All features use the Julia coordinate convention:
      - column = x-axis
      - row    = y-axis
      - top(r) = maximum row value
      - bottom(r) = minimum row value

------------------------------------------------------------------------ =#

export area, width, height, bounds_center, aspect_ratio
export moments, centroid, equivalent_ellipse
export perimeter, compactness
export convex_hull, convex_area, convex_perimeter, convexity, perforation
export feret_diameters
export number_of_holes, area_of_holes
export vectorized_boundaries, contour, to_point_list
export minimum_bounding_circle, minimum_area_bounding_rectangle, minimum_perimeter_bounding_rectangle
export central_moments, normalized_moments, scale_invariant_moments
export hu_moments, flusser_moments
export circularity, sphericity, roundness, roughness
export fiber_length, fiber_width


# Basic Geometry

"""
    area(r::Region) -> Int

Return the number of pixels in a non-complement region.

```jldoctest
julia> using Regions

julia> area(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)]))
9

julia> area(Region([Run(2, 3:3)]))
1
```
"""
function area(r::Region)
    @assert !r.complement "area is not defined for complement regions"
    return sum(length(run.rows) for run in r.runs; init=0)
end


"""
    width(r::Region) -> Int

Return the width (column extent) of the bounding box of a non-empty, non-complement region.

```jldoctest
julia> using Regions

julia> width(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)]))
3
```
"""
function width(r::Region)
    @assert !r.complement && !isempty(r.runs) "width requires a non-empty, non-complement region"
    return right(r) - left(r) + 1
end


"""
    height(r::Region) -> Int

Return the height (row extent) of the bounding box of a non-empty, non-complement region.

```jldoctest
julia> using Regions

julia> height(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)]))
3
```
"""
function height(r::Region)
    @assert !r.complement && !isempty(r.runs) "height requires a non-empty, non-complement region"
    return bottom(r) - top(r) + 1
end


"""
    bounds_center(r::Region) -> Tuple{Float64,Float64}

Return the center of the bounding box as `(column, row)`.

```jldoctest
julia> using Regions

julia> bounds_center(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)]))
(1.0, 0.0)
```
"""
function bounds_center(r::Region)
    @assert !r.complement && !isempty(r.runs) "bounds_center requires a non-empty, non-complement region"
    return ((left(r) + right(r)) / 2.0, (bottom(r) + top(r)) / 2.0)
end


"""
    aspect_ratio(r::Region) -> Float64

Return `width / height` of the bounding box.

```jldoctest
julia> using Regions

julia> aspect_ratio(Region([Run(0, 0:3), Run(1, 0:3)]))
0.5
```
"""
function aspect_ratio(r::Region)
    @assert !r.complement && !isempty(r.runs) "aspect_ratio requires a non-empty, non-complement region"
    return width(r) / height(r)
end


# Spatial Moments

# Helpers: exact integer arithmetic for sum of squares and cubes 1..n
_s2(n) = n * (n + 1) * (2n + 1) ÷ 6     # Σ k², k=1..n
_s3(n) = (n * (n + 1) ÷ 2)^2            # Σ k³, k=1..n  (= (n(n+1)/2)²)

# sum(k,   k=a:b)  — valid for any integers a,b with a≤b
_sum_rows(a, b) = (b - a + 1) * (a + b) / 2.0

# sum(k²,  k=a:b)
function _sum_rows_sq(a::Int, b::Int)
    if a >= 1
        return Float64(_s2(b) - _s2(a - 1))
    elseif b <= 0
        # Σk², a:b = Σk², (-b):(-a)  (symmetry of k²)
        return Float64(_s2(-a) - _s2(-b - 1))
    else
        # split: a:0 and 1:b
        return Float64(_s2(-a) + _s2(b))
    end
end

# sum(k³,  k=a:b)
function _sum_rows_cb(a::Int, b::Int)
    if a >= 1
        return Float64(_s3(b) - _s3(a - 1))
    elseif b <= 0
        # k³ is odd, so Σk³ a:b = -(Σk³ (-b):(-a))
        return -Float64(_s3(-a) - _s3(-b - 1))
    else
        # split: (a:0 contributes negative cubes) + (1:b positive)
        return Float64(_s3(b) - _s3(-a))
    end
end


"""
    _raw_moments(r::Region) -> NamedTuple

Compute all 10 raw spatial moments in a single pass over runs.
Column = x, row = y.  Returns `(m00, m10, m01, m20, m11, m02, m30, m21, m12, m03)`.
"""
function _raw_moments(r::Region)
    m00 = m10 = m01 = m20 = m11 = m02 = m30 = m21 = m12 = m03 = 0.0
    for run in r.runs
        c  = Float64(run.column)
        a  = run.rows.start
        b  = run.rows.stop
        n  = Float64(b - a + 1)
        sr = _sum_rows(a, b)
        s2 = _sum_rows_sq(a, b)
        s3 = _sum_rows_cb(a, b)
        m00 += n
        m10 += c * n
        m01 += sr
        m20 += c^2 * n
        m11 += c * sr
        m02 += s2
        m30 += c^3 * n
        m21 += c^2 * sr
        m12 += c * s2
        m03 += s3
    end
    return (m00=m00, m10=m10, m01=m01, m20=m20, m11=m11, m02=m02,
            m30=m30, m21=m21, m12=m12, m03=m03)
end


"""
    moments(r::Region) -> NamedTuple

Return all 10 raw spatial moments of the region as a named tuple
`(m00, m10, m01, m20, m11, m02, m30, m21, m12, m03)`.

Column is the x-axis, row is the y-axis.

```jldoctest
julia> using Regions

julia> m = moments(Region([Run(2, 3:3)]))
(m00 = 1.0, m10 = 2.0, m01 = 3.0, m20 = 4.0, m11 = 6.0, m02 = 9.0, m30 = 8.0, m21 = 12.0, m12 = 18.0, m03 = 27.0)

julia> m.m00
1.0
```
"""
function moments(r::Region)
    @assert !r.complement "moments is not defined for complement regions"
    return _raw_moments(r)
end


"""
    centroid(r::Region) -> Tuple{Float64,Float64}

Return the centroid `(column, row)` of the region.

```jldoctest
julia> using Regions

julia> centroid(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)]))
(1.0, 0.0)

julia> centroid(Region([Run(2, 3:3)]))
(2.0, 3.0)
```
"""
function centroid(r::Region)
    @assert !r.complement && !isempty(r.runs) "centroid requires a non-empty, non-complement region"
    m = _raw_moments(r)
    return (m.m10 / m.m00, m.m01 / m.m00)
end


"""
    equivalent_ellipse(r::Region) -> NamedTuple

Return the equivalent ellipse of a region as a named tuple
`(center, semi_axes, angle)`, where:
- `center` is a `Tuple{Float64,Float64}` `(column, row)`,
- `semi_axes` is a `Tuple{Float64,Float64}` `(major, minor)`,
- `angle` is in radians, measured from the column (x) axis towards the row (y) axis.

```jldoctest
julia> using Regions

julia> e = equivalent_ellipse(Region([Run(0, -1:1), Run(1, -1:1), Run(2, -1:1)]));

julia> e.center
(1.0, 0.0)

julia> round(e.angle; digits=4)
0.0
```
"""
function equivalent_ellipse(r::Region)
    @assert !r.complement && !isempty(r.runs) "equivalent_ellipse requires a non-empty, non-complement region"
    m = _raw_moments(r)
    inv_m00 = 1.0 / m.m00
    cx = m.m10 * inv_m00
    cy = m.m01 * inv_m00
    mu20 = (m.m20 - m.m10 * cx) * inv_m00
    mu11 = (m.m11 - m.m10 * cy) * inv_m00
    mu02 = (m.m02 - m.m01 * cy) * inv_m00
    D = sqrt((mu20 - mu02)^2 + 4 * mu11^2)
    sum_mu = mu20 + mu02
    major = sqrt(max(0.0, 2 * (sum_mu + D)))
    minor = sqrt(max(0.0, 2 * (sum_mu - D)))
    angle = (mu20 == mu02 && mu11 == 0.0) ? 0.0 : 0.5 * atan(2 * mu11, mu20 - mu02)
    return (center=(cx, cy), semi_axes=(major, minor), angle=angle)
end


# Perimeter and Compactness

"""
    perimeter(r::Region) -> Float64

Return the perimeter of a region measured as the number of 4-connected boundary
edges (each edge has length 1.0).

```jldoctest
julia> using Regions

julia> perimeter(Region([Run(0, 0:0)]))   # single pixel: 4 exposed edges
4.0

julia> perimeter(Region([Run(0, 0:1), Run(1, 0:1)]))   # 2×2 square: 8 edges
8.0
```
"""
function perimeter(r::Region)
    @assert !r.complement "perimeter is not defined for complement regions"
    isempty(r.runs) && return 0.0

    # Build a column-indexed dict for fast left/right-neighbour lookup
    col_map = Dict{Int, Vector{UnitRange{Int}}}()
    for run in r.runs
        push!(get!(col_map, run.column, UnitRange{Int}[]), run.rows)
    end

    p = 0.0
    for run in r.runs
        a, b = run.rows.start, run.rows.stop
        n = b - a + 1

        # Top and bottom exposed edges (boundary with rows not in the same column)
        # For each pixel in the run: exposed top edge if pixel+1 not in this run,
        # exposed bottom edge if pixel-1 not in this run.
        # Since within a single run all pixels a:b are contiguous, top/bottom of
        # the run itself each contribute 1 edge. Interior pixels share edges.
        # But a column can have multiple runs! Need to check only for the endpoints
        # that aren't adjacent to another run in the same column.
        same_col = col_map[run.column]
        # top edge of run is exposed unless there is an adjacent run in same column at b+1
        top_exposed = !any(r2 -> r2.start == b + 1, same_col)
        # bottom edge of run is exposed unless there is an adjacent run at a-1
        bot_exposed = !any(r2 -> r2.stop == a - 1, same_col)
        p += (top_exposed ? 1.0 : 0.0) + (bot_exposed ? 1.0 : 0.0)

        # Left and right exposed edges
        left_shared  = _shared_rows(a, b, col_map, run.column - 1)
        right_shared = _shared_rows(a, b, col_map, run.column + 1)
        p += (n - left_shared) + (n - right_shared)
    end
    return p
end

# Count how many rows in a:b are covered by runs in column `col`.
function _shared_rows(a::Int, b::Int, col_map::Dict{Int,Vector{UnitRange{Int}}}, col::Int)
    !haskey(col_map, col) && return 0
    shared = 0
    for r2 in col_map[col]
        lo = max(a, r2.start)
        hi = min(b, r2.stop)
        if lo <= hi
            shared += hi - lo + 1
        end
    end
    return shared
end


"""
    compactness(r::Region) -> Float64

Return the isoperimetric ratio `perimeter² / (4π·area)`.  Equals 1 for a circle,
greater than 1 for less compact shapes.

```jldoctest
julia> using Regions

julia> r = region_from_circle(0, 0, 50);

julia> compactness(r) < 1.7
true
```
"""
function compactness(r::Region)
    a = area(r)
    a == 0 && return 0.0
    p = perimeter(r)
    return p^2 / (4 * π * a)
end


# Convex Hull and Derived Features

# Extract the corner coordinates of every run's bounding rectangle (half-integer
# coordinates so that a rectangular region's convex_area equals its pixel area).
function _run_corners(r::Region)
    pts = Vector{Tuple{Float64,Float64}}()
    sizehint!(pts, 4 * length(r.runs))
    for run in r.runs
        c = Float64(run.column)
        a = Float64(run.rows.start)
        b = Float64(run.rows.stop)
        push!(pts, (c - 0.5, a - 0.5))
        push!(pts, (c - 0.5, b + 0.5))
        push!(pts, (c + 0.5, a - 0.5))
        push!(pts, (c + 0.5, b + 0.5))
    end
    return pts
end


"""
    convex_hull(r::Region) -> Vector{Tuple{Float64,Float64}}

Return the convex hull of the region as an ordered list of vertices (CCW).
Coordinates are half-integer pixel corners.

```jldoctest
julia> using Regions

julia> h = convex_hull(Region([Run(0, 0:1), Run(1, 0:1)]));

julia> length(h)
4
```
"""
function convex_hull(r::Region)
    @assert !r.complement && !isempty(r.runs) "convex_hull requires a non-empty, non-complement region"
    return _monotone_chain(_run_corners(r))
end


# Shoelace formula for polygon area (signed; take abs value).
function _polygon_area(hull::Vector{Tuple{Float64,Float64}})
    n = length(hull)
    n < 3 && return 0.0
    s = 0.0
    for i in 1:n
        j = i % n + 1
        s += hull[i][1] * hull[j][2] - hull[j][1] * hull[i][2]
    end
    return abs(s) / 2.0
end

# Sum of edge lengths of a polygon.
function _polygon_perimeter(hull::Vector{Tuple{Float64,Float64}})
    n = length(hull)
    n == 0 && return 0.0
    s = 0.0
    for i in 1:n
        j = i % n + 1
        dx = hull[j][1] - hull[i][1]
        dy = hull[j][2] - hull[i][2]
        s += sqrt(dx^2 + dy^2)
    end
    return s
end


"""
    convex_area(r::Region) -> Float64

Return the area of the convex hull (in pixel units).

```jldoctest
julia> using Regions

julia> convex_area(Region([Run(0, 0:1), Run(1, 0:1)]))
4.0
```
"""
function convex_area(r::Region)
    @assert !r.complement && !isempty(r.runs) "convex_area requires a non-empty, non-complement region"
    return _polygon_area(convex_hull(r))
end


"""
    convex_perimeter(r::Region) -> Float64

Return the perimeter of the convex hull.

```jldoctest
julia> using Regions

julia> convex_perimeter(Region([Run(0, 0:1), Run(1, 0:1)]))
8.0
```
"""
function convex_perimeter(r::Region)
    @assert !r.complement && !isempty(r.runs) "convex_perimeter requires a non-empty, non-complement region"
    return _polygon_perimeter(convex_hull(r))
end


"""
    convexity(r::Region) -> Float64

Return `area / convex_area`.  Equals 1 for convex regions, less than 1 for concave ones.

```jldoctest
julia> using Regions

julia> convexity(Region([Run(0, 0:1), Run(1, 0:1)]))
1.0
```
"""
function convexity(r::Region)
    ca = convex_area(r)
    ca == 0.0 && return 0.0
    return area(r) / ca
end


"""
    perforation(r::Region) -> Float64

Return `(convex_area - area) / convex_area`.

```jldoctest
julia> using Regions

julia> perforation(Region([Run(0, 0:1), Run(1, 0:1)]))
0.0
```
"""
function perforation(r::Region)
    ca = convex_area(r)
    ca == 0.0 && return 0.0
    return (ca - area(r)) / ca
end


"""
    feret_diameters(r::Region) -> Tuple{Float64,Float64}

Return `(min_feret, max_feret)` — the minimum and maximum caliper widths —
computed via rotating calipers on the convex hull.

```jldoctest
julia> using Regions

julia> mn, mx = feret_diameters(Region([Run(0, 0:0)]));

julia> mn ≈ 1.0 && mx ≈ sqrt(2)
true
```
"""
function feret_diameters(r::Region)
    @assert !r.complement && !isempty(r.runs) "feret_diameters requires a non-empty, non-complement region"
    hull = convex_hull(r)
    n = length(hull)
    if n == 0
        return (0.0, 0.0)
    elseif n == 1
        return (0.0, 0.0)
    elseif n == 2
        dx = hull[2][1] - hull[1][1]
        dy = hull[2][2] - hull[1][2]
        d = sqrt(dx^2 + dy^2)
        return (d, d)
    end

    min_f = Inf

    # Minimum Feret: achieved in a direction normal to some edge.
    for i in 1:n
        j = i % n + 1
        ex = hull[j][1] - hull[i][1]
        ey = hull[j][2] - hull[i][2]
        len = sqrt(ex^2 + ey^2)
        len == 0.0 && continue
        nx = -ey / len
        ny =  ex / len
        projs = [hull[k][1] * nx + hull[k][2] * ny for k in 1:n]
        min_f = min(min_f, maximum(projs) - minimum(projs))
    end

    # Maximum Feret = diameter of convex hull = max distance between any two vertices.
    max_f = 0.0
    for i in 1:n
        for j in (i+1):n
            dx = hull[j][1] - hull[i][1]
            dy = hull[j][2] - hull[i][2]
            max_f = max(max_f, sqrt(dx^2 + dy^2))
        end
    end

    return (min_f, max_f)
end


# Hole Features

"""
    number_of_holes(r::Region) -> Int

Return the number of holes (connected background components fully enclosed by the region).

```jldoctest
julia> using Regions

julia> r = Region([Run(c, 0:4) for c in 0:4]);   # solid 5×5 square — no holes

julia> number_of_holes(r)
0
```
"""
function number_of_holes(r::Region)
    return length(holes(r))
end


"""
    area_of_holes(r::Region) -> Int

Return the total pixel count of all holes in the region.

```jldoctest
julia> using Regions

julia> r = Region([Run(c, 0:4) for c in 0:4]);   # solid 5×5 square — no holes

julia> area_of_holes(r)
0
```
"""
function area_of_holes(r::Region)
    return sum(area(h) for h in holes(r); init=0)
end


# Polygon List (Boundary Vectorisation)

"""
    vectorized_boundaries(r::Region) -> Vector{PointList}

Convert a region to a list of closed boundary polygons. Outer boundaries wind
clockwise; hole boundaries wind counter-clockwise (interior always to the right
of travel direction). Coordinates use pixel-corner convention: a pixel at
`(col, row)` has its corners at `(col±0.5, row±0.5)`.

The result may contain collinear midpoints on straight edges; call
`remove_collinear(poly)` on each polygon to simplify.

```jldoctest
julia> using Regions

julia> polys = vectorized_boundaries(Region([Run(0, 0:0)]));

julia> length(polys)
1

julia> length(polys[1])
4
```
"""
function vectorized_boundaries(r::Region)
    @assert !r.complement "vectorized_boundaries: not defined for complement regions"
    isempty(r.runs) && return Vector{PointList}()

    col_map = Dict{Int,Vector{UnitRange{Int}}}()
    for run in r.runs
        push!(get!(col_map, run.column, UnitRange{Int}[]), run.rows)
    end

    # Sub-ranges of y_start:y_stop NOT covered by any run in `col`.
    # Relies on col_map[col] being sorted by range start (guaranteed by run sort order).
    function uncovered(y_start, y_stop, col)
        result = UnitRange{Int}[]
        cur = y_start
        for r2 in get(col_map, col, UnitRange{Int}[])
            r2.stop  < cur    && continue
            r2.start > y_stop && break
            r2.start > cur    && push!(result, cur:(r2.start - 1))
            cur = r2.stop + 1
            cur > y_stop && break
        end
        cur <= y_stop && push!(result, cur:y_stop)
        return result
    end

    segments = Dict{Tuple{Int,Int},Tuple{Int,Int}}()
    add(fx, fy, tx, ty) = (segments[(fx, fy)] = (tx, ty))

    for run in r.runs
        x  = run.column
        ya = run.rows.start
        yb = run.rows.stop

        add(x,   ya,   x+1, ya)    # bottom edge →
        add(x+1, yb+1, x,   yb+1) # top edge    ←

        for sub in uncovered(ya, yb, x-1)          # left side ↑
            add(x, sub.stop+1, x, sub.start)
        end
        for sub in uncovered(ya, yb, x+1)          # right side ↓
            add(x+1, sub.start, x+1, sub.stop+1)
        end
    end

    polygons = Vector{PointList}()
    while !isempty(segments)
        poly = PointList()
        from_pt = first(keys(segments))
        while haskey(segments, from_pt)
            to_pt = segments[from_pt]
            push!(poly, (Float64(from_pt[1]) - 0.5, Float64(from_pt[2]) - 0.5))
            delete!(segments, from_pt)
            from_pt = to_pt
        end
        push!(polygons, poly)
    end
    return polygons
end


"""
    to_point_list(r::Region) -> PointList

Flatten all boundary polygons of `r` into a single `PointList`.
Equivalent to concatenating all polygons returned by [`vectorized_boundaries`](@ref).

```jldoctest
julia> using Regions

julia> length(to_point_list(Region([Run(0, 0:0)])))
4
```
"""
function to_point_list(r::Region)
    result = PointList()
    for poly in vectorized_boundaries(r)
        append!(result, poly)
    end
    return result
end


"""
    contour(r::Region) -> PointList

Return the first (outer) boundary polygon of `r` as a `PointList`.
Equivalent to `vectorized_boundaries(r)[1]`.

```jldoctest
julia> using Regions

julia> length(contour(Region([Run(0, 0:0)])))
4
```
"""
function contour(r::Region)
    @assert !r.complement && !isempty(r.runs) "contour requires a non-empty, non-complement region"
    return vectorized_boundaries(r)[1]
end


# Bounding-Geometry Adapters for Region

"""
    minimum_bounding_circle(r::Region) -> NamedTuple

Return the minimum enclosing circle of `r` as `(center, radius)`. Delegates to
[`minimum_bounding_circle(::PointList)`](@ref) on the region's convex hull.

```jldoctest
julia> using Regions

julia> c = minimum_bounding_circle(region_from_box(0, 0, 4, 4));

julia> c.center[1] ≈ 2.0 && c.center[2] ≈ 2.0 && c.radius ≈ 2.5 * sqrt(2)
true
```
"""
function minimum_bounding_circle(r::Region)
    @assert !r.complement && !isempty(r.runs) "minimum_bounding_circle requires a non-empty, non-complement region"
    return minimum_bounding_circle(convex_hull(r))
end

"""
    minimum_area_bounding_rectangle(r::Region) -> NamedTuple

Return the minimum-area bounding rectangle of `r` as
`(corners, width, height, angle, area)`. Delegates to
[`minimum_area_bounding_rectangle(::PointList)`](@ref) on the region's convex hull.

```jldoctest
julia> using Regions

julia> rect = minimum_area_bounding_rectangle(region_from_box(0, 0, 4, 2));

julia> rect.area ≈ 5.0 * 3.0
true
```
"""
function minimum_area_bounding_rectangle(r::Region)
    @assert !r.complement && !isempty(r.runs) "minimum_area_bounding_rectangle requires a non-empty, non-complement region"
    return minimum_area_bounding_rectangle(convex_hull(r))
end

"""
    minimum_perimeter_bounding_rectangle(r::Region) -> NamedTuple

Return the minimum-perimeter bounding rectangle of `r` as
`(corners, width, height, angle, perimeter)`. Delegates to
[`minimum_perimeter_bounding_rectangle(::PointList)`](@ref) on the region's convex hull.

```jldoctest
julia> using Regions

julia> rect = minimum_perimeter_bounding_rectangle(region_from_box(0, 0, 4, 2));

julia> rect.perimeter ≈ 2 * (5.0 + 3.0)
true
```
"""
function minimum_perimeter_bounding_rectangle(r::Region)
    @assert !r.complement && !isempty(r.runs) "minimum_perimeter_bounding_rectangle requires a non-empty, non-complement region"
    return minimum_perimeter_bounding_rectangle(convex_hull(r))
end


# Central, Normalized, and Invariant Moments

"""
    central_moments(r::Region) -> NamedTuple

Return the central moments `(μ20, μ11, μ02, μ30, μ21, μ12, μ03)` of a region.
Central moments are computed relative to the region's centroid; `μ10 = μ01 = 0`
by definition and are not included. `μ00` equals `area(r)` and is also omitted.

The standard relations to the raw moments `mij` (with `x̄ = m10/m00`,
`ȳ = m01/m00`) are:

- `μ20 = m20 - x̄·m10`
- `μ11 = m11 - x̄·m01`
- `μ02 = m02 - ȳ·m01`
- `μ30 = m30 - 3·x̄·m20 + 2·x̄²·m10`
- `μ21 = m21 - 2·x̄·m11 - ȳ·m20 + 2·x̄²·m01`
- `μ12 = m12 - 2·ȳ·m11 - x̄·m02 + 2·ȳ²·m10`
- `μ03 = m03 - 3·ȳ·m02 + 2·ȳ²·m01`

```jldoctest
julia> using Regions

julia> μ = central_moments(Region([Run(c, -1:1) for c in -1:1]));   # 3×3 box centred at origin

julia> μ.μ11 ≈ 0.0 && μ.μ30 ≈ 0.0 && μ.μ03 ≈ 0.0
true

julia> μ.μ20 ≈ 6.0 && μ.μ02 ≈ 6.0
true
```
"""
function central_moments(r::Region)
    @assert !r.complement && !isempty(r.runs) "central_moments requires a non-empty, non-complement region"
    m = _raw_moments(r)
    x̄ = m.m10 / m.m00
    ȳ = m.m01 / m.m00
    μ20 = m.m20 - x̄ * m.m10
    μ11 = m.m11 - x̄ * m.m01
    μ02 = m.m02 - ȳ * m.m01
    μ30 = m.m30 - 3x̄ * m.m20 + 2x̄^2 * m.m10
    μ21 = m.m21 - 2x̄ * m.m11 - ȳ * m.m20 + 2x̄^2 * m.m01
    μ12 = m.m12 - 2ȳ * m.m11 - x̄ * m.m02 + 2ȳ^2 * m.m10
    μ03 = m.m03 - 3ȳ * m.m02 + 2ȳ^2 * m.m01
    return (μ20=μ20, μ11=μ11, μ02=μ02, μ30=μ30, μ21=μ21, μ12=μ12, μ03=μ03)
end


"""
    normalized_moments(r::Region) -> NamedTuple

Return the scale-normalized central moments `(η20, η11, η02, η30, η21, η12, η03)`.
Each `η_pq = μ_pq / μ00^γ` with `γ = (p + q) / 2 + 1`, so `η_pq` is invariant
under uniform scaling of the region.

[`scale_invariant_moments`](@ref) is an alias for this function.

```jldoctest
julia> using Regions

julia> η = normalized_moments(region_from_circle(0, 0, 30));

julia> abs(η.η11) < 1e-3
true
```
"""
function normalized_moments(r::Region)
    @assert !r.complement && !isempty(r.runs) "normalized_moments requires a non-empty, non-complement region"
    μ = central_moments(r)
    μ00 = Float64(area(r))
    η(p, q, val) = val / μ00^((p + q) / 2 + 1)
    return (η20=η(2, 0, μ.μ20),
            η11=η(1, 1, μ.μ11),
            η02=η(0, 2, μ.μ02),
            η30=η(3, 0, μ.μ30),
            η21=η(2, 1, μ.μ21),
            η12=η(1, 2, μ.μ12),
            η03=η(0, 3, μ.μ03))
end

"""
    scale_invariant_moments(r::Region) -> NamedTuple

Alias for [`normalized_moments`](@ref). Returns the scale-invariant central
moments `(η20, η11, η02, η30, η21, η12, η03)`.
"""
scale_invariant_moments(r::Region) = normalized_moments(r)


"""
    hu_moments(r::Region) -> NTuple{7,Float64}

Return Hu's seven moment invariants `(I1, I2, I3, I4, I5, I6, I7)` computed from
the normalized central moments. Hu moments are invariant under translation,
uniform scaling and rotation, so they form a classic shape descriptor for
rotation-and-scale-tolerant matching.

The formulas (Hu, 1962):

- `I1 = η20 + η02`
- `I2 = (η20 − η02)² + 4·η11²`
- `I3 = (η30 − 3·η12)² + (3·η21 − η03)²`
- `I4 = (η30 + η12)² + (η21 + η03)²`
- `I5 = (η30 − 3·η12)·(η30 + η12)·[(η30 + η12)² − 3·(η21 + η03)²] +
        (3·η21 − η03)·(η21 + η03)·[3·(η30 + η12)² − (η21 + η03)²]`
- `I6 = (η20 − η02)·[(η30 + η12)² − (η21 + η03)²] +
        4·η11·(η30 + η12)·(η21 + η03)`
- `I7 = (3·η21 − η03)·(η30 + η12)·[(η30 + η12)² − 3·(η21 + η03)²] −
        (η30 − 3·η12)·(η21 + η03)·[3·(η30 + η12)² − (η21 + η03)²]`

```jldoctest
julia> using Regions

julia> I = hu_moments(region_from_circle(0, 0, 20));

julia> abs(I[2]) < 1e-3   # circle: rotational symmetry → I2 ≈ 0
true
```
"""
function hu_moments(r::Region)
    η = normalized_moments(r)
    a = η.η30 - 3η.η12
    b = 3η.η21 - η.η03
    p = η.η30 + η.η12
    q = η.η21 + η.η03
    I1 = η.η20 + η.η02
    I2 = (η.η20 - η.η02)^2 + 4η.η11^2
    I3 = a^2 + b^2
    I4 = p^2 + q^2
    I5 = a * p * (p^2 - 3q^2) + b * q * (3p^2 - q^2)
    I6 = (η.η20 - η.η02) * (p^2 - q^2) + 4η.η11 * p * q
    I7 = b * p * (p^2 - 3q^2) - a * q * (3p^2 - q^2)
    return (I1, I2, I3, I4, I5, I6, I7)
end


"""
    flusser_moments(r::Region) -> NTuple{4,Float64}

Return the first four Flusser–Suk affine moment invariants
`(I1, I2, I3, I4)` (Flusser & Suk, 1993). These are invariant under general
affine transformations (translation, scaling, rotation, shear), which makes
them more robust than [`hu_moments`](@ref) when the imaged object can be
viewed under perspective change.

The invariants are formed from central moments `μij` and the area `μ00`:

- `I1 = (μ20·μ02 − μ11²) / μ00^4`
- `I2 = (μ30²·μ03² − 6·μ30·μ21·μ12·μ03 + 4·μ30·μ12³ + 4·μ21³·μ03 −
         3·μ21²·μ12²) / μ00^10`
- `I3 = (μ20·(μ21·μ03 − μ12²) − μ11·(μ30·μ03 − μ21·μ12) +
         μ02·(μ30·μ12 − μ21²)) / μ00^7`
- `I4 = (μ20³·μ03² − 6·μ20²·μ11·μ12·μ03 − 6·μ20²·μ02·μ21·μ03 +
         9·μ20²·μ02·μ12² + 12·μ20·μ11²·μ21·μ03 +
         6·μ20·μ11·μ02·μ30·μ03 − 18·μ20·μ11·μ02·μ21·μ12 −
         8·μ11³·μ30·μ03 − 6·μ20·μ02²·μ30·μ12 + 9·μ20·μ02²·μ21² +
         12·μ11²·μ02·μ30·μ12 − 6·μ11·μ02²·μ30·μ21 +
         μ02³·μ30²) / μ00^11`

```jldoctest
julia> using Regions

julia> F = flusser_moments(region_from_circle(0, 0, 20));

julia> F[1] > 0    # I1 strictly positive for any non-degenerate shape
true
```
"""
function flusser_moments(r::Region)
    μ   = central_moments(r)
    μ00 = Float64(area(r))
    μ20, μ11, μ02 = μ.μ20, μ.μ11, μ.μ02
    μ30, μ21, μ12, μ03 = μ.μ30, μ.μ21, μ.μ12, μ.μ03

    I1 = (μ20 * μ02 - μ11^2) / μ00^4

    I2 = (μ30^2 * μ03^2 - 6μ30 * μ21 * μ12 * μ03 + 4μ30 * μ12^3 +
          4μ21^3 * μ03 - 3μ21^2 * μ12^2) / μ00^10

    I3 = (μ20 * (μ21 * μ03 - μ12^2) -
          μ11 * (μ30 * μ03 - μ21 * μ12) +
          μ02 * (μ30 * μ12 - μ21^2)) / μ00^7

    I4 = (μ20^3 * μ03^2 -
          6μ20^2 * μ11 * μ12 * μ03 -
          6μ20^2 * μ02 * μ21 * μ03 +
          9μ20^2 * μ02 * μ12^2 +
          12μ20 * μ11^2 * μ21 * μ03 +
          6μ20 * μ11 * μ02 * μ30 * μ03 -
          18μ20 * μ11 * μ02 * μ21 * μ12 -
          8μ11^3 * μ30 * μ03 -
          6μ20 * μ02^2 * μ30 * μ12 +
          9μ20 * μ02^2 * μ21^2 +
          12μ11^2 * μ02 * μ30 * μ12 -
          6μ11 * μ02^2 * μ30 * μ21 +
          μ02^3 * μ30^2) / μ00^11

    return (I1, I2, I3, I4)
end


# Shape Descriptors

"""
    circularity(r::Region) -> Float64

Return `2·√(π·area) / perimeter`. Equals 1 for an ideal disk and decreases
towards 0 for shapes with a longer boundary relative to their area. This is
different from [`compactness`](@ref), which is the isoperimetric ratio
`perimeter² / (4π·area)`.

```jldoctest
julia> using Regions

julia> 0.0 < circularity(region_from_circle(0, 0, 50)) ≤ 1.0
true
```
"""
function circularity(r::Region)
    p = perimeter(r)
    p == 0.0 && return 0.0
    return 2.0 * sqrt(π * area(r)) / p
end


"""
    sphericity(r::Region) -> Float64

Return `2·√(area/π) / max_feret`. Equals 1 for an ideal disk and decreases
towards 0 for elongated shapes — the ratio of the equivalent-area-disk
diameter to the longest caliper width.

```jldoctest
julia> using Regions

julia> sphericity(region_from_circle(0, 0, 50)) > 0.95
true
```
"""
function sphericity(r::Region)
    _, max_f = feret_diameters(r)
    max_f == 0.0 && return 0.0
    return 2.0 * sqrt(area(r) / π) / max_f
end


"""
    roundness(r::Region) -> Float64

Return `area / (π·r²)` where `r` is the radius of the minimum bounding circle.
Equals 1 for an ideal disk and decreases for shapes that do not fill their
bounding circle.

```jldoctest
julia> using Regions

julia> 0.0 < roundness(region_from_circle(0, 0, 50)) ≤ 1.0
true
```
"""
function roundness(r::Region)
    c = minimum_bounding_circle(r)
    c.radius == 0.0 && return 0.0
    return area(r) / (π * c.radius^2)
end


"""
    roughness(r::Region) -> Float64

Return `perimeter / convex_perimeter`. Equals 1 for a convex region (whose
4-connected boundary length equals its convex-hull perimeter) and exceeds 1
when the actual boundary stair-steps or has concavities, making it longer
than the convex hull.

```jldoctest
julia> using Regions

julia> roughness(region_from_box(0, 0, 4, 4)) ≈ 1.0    # rectangle is convex
true

julia> roughness(region_from_circle(0, 0, 50)) > 1.0   # stair-stepped circle
true
```
"""
function roughness(r::Region)
    cp = convex_perimeter(r)
    cp == 0.0 && return 0.0
    return perimeter(r) / cp
end


# Fiber Metrics

"""
    fiber_length(r::Region) -> Float64

Return half of the 4-connected perimeter — `0.5 · perimeter(r)`. For
elongated, fiber-shaped blobs this approximates the length along the fiber
axis (the perimeter traces one side of the fiber going out and the other
side coming back).

For a circle this gives `π·r` rather than the diameter, so the name "length"
only carries its intended meaning on truly fiber-shaped regions.

```jldoctest
julia> using Regions

julia> fiber_length(Region([Run(0, 0:0)]))    # single pixel: perimeter 4
2.0

julia> fiber_length(region_from_box(0, 0, 2, 2)) ≈ 0.5 * perimeter(region_from_box(0, 0, 2, 2))
true
```
"""
fiber_length(r::Region) = 0.5 * perimeter(r)


"""
    fiber_width(r::Region) -> Float64

Return `2.0 · maximum(distance_transform(r))` — twice the largest city-block
distance from any region pixel to the background. Geometrically this is the
diameter of the biggest city-block diamond that fits inside the region; for
thin, fiber-shaped blobs it closely tracks the cross-sectional width.

Because the underlying [`distance_transform`](@ref) uses 4-connected
(Manhattan) distance, `fiber_width` overestimates the Euclidean width for
non-thin shapes — e.g. a 3×3 square has `fiber_width = 4.0`, not `3.0`. This
matches the C++ reference implementation; if you need an Euclidean width,
use [`feret_diameters`](@ref) instead.

```jldoctest
julia> using Regions

julia> fiber_width(Region([Run(0, 0:0)]))            # single pixel
2.0

julia> fiber_width(region_from_box(0, 0, 2, 2))      # 3×3 square: max DT = 2
4.0
```
"""
fiber_width(r::Region) = 2.0 * maximum(distance_transform(r))
