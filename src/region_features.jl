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
    return top(r) - bottom(r) + 1
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

julia> abs(compactness(r) - 1.0) < 0.01
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

# Andrew's monotone chain — returns hull in CCW order.
function _monotone_chain(pts::Vector{Tuple{Float64,Float64}})
    n = length(pts)
    n <= 1 && return copy(pts)
    sorted = sort(pts)   # lexicographic (x first, then y)
    hull = Vector{Tuple{Float64,Float64}}()
    sizehint!(hull, 2n)

    _cross(o, a, b) = (a[1]-o[1])*(b[2]-o[2]) - (a[2]-o[2])*(b[1]-o[1])

    # lower hull
    for p in sorted
        while length(hull) >= 2 && _cross(hull[end-1], hull[end], p) <= 0
            pop!(hull)
        end
        push!(hull, p)
    end
    # upper hull
    lower_len = length(hull) + 1
    for p in reverse(sorted)
        while length(hull) >= lower_len && _cross(hull[end-1], hull[end], p) <= 0
            pop!(hull)
        end
        push!(hull, p)
    end
    pop!(hull)   # last point equals first
    return hull
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

julia> mn ≈ 1.0 && mx ≈ 1.0
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
