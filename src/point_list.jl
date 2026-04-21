#= ------------------------------------------------------------------------

    Point List Algorithms

    Geometry operations on lists of 2D points.
    A point list is Vector{Tuple{Float64,Float64}}, aliased as PointList.
    Coordinate convention: (column, row) = (x, y).

------------------------------------------------------------------------ =#

export PointList
export centroid
export bounding_box
export convex_hull, convex_hull_cw
export remove_collinear
export minimum_width, maximum_width, feret_diameters
export minimum_area_bounding_rectangle, minimum_perimeter_bounding_rectangle
export minimum_bounding_circle
export translate

"""
    PointList

Alias for `Vector{Tuple{Float64,Float64}}`. Each element is `(column, row)`.
"""
const PointList = Vector{Tuple{Float64,Float64}}

# Andrew's monotone chain — returns hull in CCW order.
function _monotone_chain(pts::PointList)
    n = length(pts)
    n <= 1 && return copy(pts)
    sorted = sort(pts)
    hull = PointList()
    sizehint!(hull, 2n)

    _cross(o, a, b) = (a[1]-o[1])*(b[2]-o[2]) - (a[2]-o[2])*(b[1]-o[1])

    for p in sorted
        while length(hull) >= 2 && _cross(hull[end-1], hull[end], p) <= 0
            pop!(hull)
        end
        push!(hull, p)
    end
    lower_len = length(hull) + 1
    for p in reverse(sorted)
        while length(hull) >= lower_len && _cross(hull[end-1], hull[end], p) <= 0
            pop!(hull)
        end
        push!(hull, p)
    end
    pop!(hull)
    return hull
end


"""
    centroid(pts::PointList) -> Tuple{Float64,Float64}

Return the centroid (arithmetic mean) of the points as `(column, row)`.

```jldoctest
julia> using Regions

julia> centroid([(0.0,0.0),(2.0,0.0),(2.0,2.0),(0.0,2.0)])
(1.0, 1.0)
```
"""
function centroid(pts::PointList)
    @assert !isempty(pts) "centroid requires a non-empty point list"
    n = length(pts)
    return (sum(first, pts) / n, sum(last, pts) / n)
end


"""
    bounding_box(pts::PointList) -> NamedTuple

Return the axis-aligned bounding box of a point list as
`(xmin, xmax, ymin, ymax)`.

```jldoctest
julia> using Regions

julia> bb = bounding_box([(1.0,2.0),(3.0,4.0),(2.0,1.0)]);

julia> bb.xmin, bb.xmax, bb.ymin, bb.ymax
(1.0, 3.0, 1.0, 4.0)
```
"""
function bounding_box(pts::PointList)
    @assert !isempty(pts) "bounding_box requires a non-empty point list"
    return (xmin=minimum(first, pts), xmax=maximum(first, pts),
            ymin=minimum(last,  pts), ymax=maximum(last,  pts))
end


"""
    convex_hull(pts::PointList) -> PointList

Return the convex hull of a point list as CCW-ordered vertices, using
Andrew's monotone chain algorithm.

```jldoctest
julia> using Regions

julia> pts = [(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0),(0.5,0.5)];

julia> h = convex_hull(pts);

julia> length(h)
4
```
"""
function convex_hull(pts::PointList)
    @assert !isempty(pts) "convex_hull requires a non-empty point list"
    return _monotone_chain(pts)
end


"""
    convex_hull_cw(pts::PointList) -> PointList

Return the convex hull of a point list in clockwise order.

```jldoctest
julia> using Regions

julia> pts = [(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)];

julia> convex_hull_cw(pts) == reverse(convex_hull(pts))
true
```
"""
convex_hull_cw(pts::PointList) = reverse(convex_hull(pts))


"""
    remove_collinear(pts::PointList) -> PointList

Remove collinear consecutive vertices from a polygon. A vertex is removed if
it lies exactly on the line through its two neighbours.

```jldoctest
julia> using Regions

julia> pts = [(0.0,0.0),(0.5,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)];

julia> remove_collinear(pts)
4-element Vector{Tuple{Float64, Float64}}:
 (0.0, 0.0)
 (1.0, 0.0)
 (1.0, 1.0)
 (0.0, 1.0)
```
"""
function remove_collinear(pts::PointList)
    n = length(pts)
    n < 3 && return copy(pts)
    result = PointList()
    for i in 1:n
        a = pts[mod1(i-1, n)]
        b = pts[i]
        c = pts[mod1(i+1, n)]
        cross = (b[1]-a[1])*(c[2]-a[2]) - (b[2]-a[2])*(c[1]-a[1])
        abs(cross) > 0.0 && push!(result, b)
    end
    return result
end


"""
    feret_diameters(pts::PointList) -> Tuple{Float64,Float64}

Return `(min_feret, max_feret)` — minimum and maximum caliper widths —
computed via rotating calipers on the convex hull of `pts`.

```jldoctest
julia> using Regions

julia> mn, mx = feret_diameters([(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)]);

julia> mn ≈ 1.0 && mx ≈ sqrt(2)
true
```
"""
function feret_diameters(pts::PointList)
    @assert !isempty(pts) "feret_diameters requires a non-empty point list"
    hull = convex_hull(pts)
    n = length(hull)
    n <= 1 && return (0.0, 0.0)
    if n == 2
        dx = hull[2][1] - hull[1][1]
        dy = hull[2][2] - hull[1][2]
        d = sqrt(dx^2 + dy^2)
        return (d, d)
    end

    min_f = Inf
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

    max_f = 0.0
    for i in eachindex(hull)
        for j in (i+1):lastindex(hull)
            dx = hull[j][1] - hull[i][1]
            dy = hull[j][2] - hull[i][2]
            max_f = max(max_f, sqrt(dx^2 + dy^2))
        end
    end

    return (min_f, max_f)
end


"""
    minimum_width(pts::PointList) -> Float64

Return the minimum caliper width (minimum Feret diameter) of a point list.

```jldoctest
julia> using Regions

julia> minimum_width([(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)]) ≈ 1.0
true
```
"""
minimum_width(pts::PointList) = feret_diameters(pts)[1]


"""
    maximum_width(pts::PointList) -> Float64

Return the maximum caliper width (maximum Feret diameter) of a point list.

```jldoctest
julia> using Regions

julia> maximum_width([(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)]) ≈ sqrt(2)
true
```
"""
maximum_width(pts::PointList) = feret_diameters(pts)[2]


# Bounding rectangle aligned with edge i→(i%n+1) of a convex hull.
function _edge_bounding_rect(hull::PointList, i::Int)
    n = length(hull)
    j = i % n + 1
    ex = hull[j][1] - hull[i][1]
    ey = hull[j][2] - hull[i][2]
    len = sqrt(ex^2 + ey^2)
    len == 0.0 && return nothing
    ux, uy = ex/len, ey/len    # unit edge direction
    nx, ny = -uy, ux           # unit left-pointing normal (CCW hull → inward)

    eprojs = [hull[k][1]*ux + hull[k][2]*uy for k in 1:n]
    nprojs = [hull[k][1]*nx + hull[k][2]*ny for k in 1:n]
    emin, emax = extrema(eprojs)
    nmin, nmax = extrema(nprojs)
    w = emax - emin
    h = nmax - nmin

    corners = PointList([
        (emin*ux + nmin*nx, emin*uy + nmin*ny),
        (emax*ux + nmin*nx, emax*uy + nmin*ny),
        (emax*ux + nmax*nx, emax*uy + nmax*ny),
        (emin*ux + nmax*nx, emin*uy + nmax*ny),
    ])
    return (corners=corners, width=w, height=h, angle=atan(uy, ux))
end


"""
    minimum_area_bounding_rectangle(pts::PointList) -> NamedTuple

Return the minimum-area bounding rectangle via rotating calipers on the
convex hull. Returns `(corners, width, height, angle, area)` where `corners`
is a `PointList` of 4 CCW vertices and `angle` is the long-axis rotation in
radians.

```jldoctest
julia> using Regions

julia> r = minimum_area_bounding_rectangle([(0.0,0.0),(2.0,0.0),(2.0,1.0),(0.0,1.0)]);

julia> r.area ≈ 2.0
true
```
"""
function minimum_area_bounding_rectangle(pts::PointList)
    @assert !isempty(pts) "minimum_area_bounding_rectangle requires a non-empty point list"
    hull = convex_hull(pts)
    best_area = Inf
    best = nothing
    for i in 1:length(hull)
        rect = _edge_bounding_rect(hull, i)
        rect === nothing && continue
        a = rect.width * rect.height
        if a < best_area
            best_area = a
            best = merge(rect, (area=a,))
        end
    end
    best === nothing && return (corners=hull, width=0.0, height=0.0, angle=0.0, area=0.0)
    return best
end


"""
    minimum_perimeter_bounding_rectangle(pts::PointList) -> NamedTuple

Return the minimum-perimeter bounding rectangle via rotating calipers on the
convex hull. Returns `(corners, width, height, angle, perimeter)` where
`corners` is a `PointList` of 4 CCW vertices and `angle` is the long-axis
rotation in radians.

```jldoctest
julia> using Regions

julia> r = minimum_perimeter_bounding_rectangle([(0.0,0.0),(2.0,0.0),(2.0,1.0),(0.0,1.0)]);

julia> r.perimeter ≈ 6.0
true
```
"""
function minimum_perimeter_bounding_rectangle(pts::PointList)
    @assert !isempty(pts) "minimum_perimeter_bounding_rectangle requires a non-empty point list"
    hull = convex_hull(pts)
    best_peri = Inf
    best = nothing
    for i in 1:length(hull)
        rect = _edge_bounding_rect(hull, i)
        rect === nothing && continue
        p = 2 * (rect.width + rect.height)
        if p < best_peri
            best_peri = p
            best = merge(rect, (perimeter=p,))
        end
    end
    best === nothing && return (corners=hull, width=0.0, height=0.0, angle=0.0, perimeter=0.0)
    return best
end


"""
    minimum_bounding_circle(pts::PointList) -> NamedTuple

Return the minimum enclosing circle of a point list as `(center, radius)`.
Uses Welzl's incremental algorithm.

```jldoctest
julia> using Regions

julia> c = minimum_bounding_circle([(0.0,0.0),(2.0,0.0),(2.0,2.0),(0.0,2.0)]);

julia> c.center[1] ≈ 1.0 && c.center[2] ≈ 1.0 && c.radius ≈ sqrt(2)
true
```
"""
function minimum_bounding_circle(pts::PointList)
    @assert !isempty(pts) "minimum_bounding_circle requires a non-empty point list"

    function _circumcircle(a, b, c)
        ax, ay = a;  bx, by = b;  cx, cy = c
        D = 2*(ax*(by-cy) + bx*(cy-ay) + cx*(ay-by))
        if abs(D) < 1e-10
            dab = (ax-bx)^2 + (ay-by)^2
            dac = (ax-cx)^2 + (ay-cy)^2
            dbc = (bx-cx)^2 + (by-cy)^2
            if dab >= dac && dab >= dbc
                return ((ax+bx)/2, (ay+by)/2, sqrt(dab)/2)
            elseif dac >= dbc
                return ((ax+cx)/2, (ay+cy)/2, sqrt(dac)/2)
            else
                return ((bx+cx)/2, (by+cy)/2, sqrt(dbc)/2)
            end
        end
        ux = ((ax^2+ay^2)*(by-cy) + (bx^2+by^2)*(cy-ay) + (cx^2+cy^2)*(ay-by)) / D
        uy = ((ax^2+ay^2)*(cx-bx) + (bx^2+by^2)*(ax-cx) + (cx^2+cy^2)*(bx-ax)) / D
        return (ux, uy, sqrt((ax-ux)^2 + (ay-uy)^2))
    end

    _inside(cx, cy, r, p) = (p[1]-cx)^2 + (p[2]-cy)^2 <= (r + 1e-10)^2

    cx, cy = pts[1]
    r = 0.0
    for i in 2:length(pts)
        p = pts[i]
        _inside(cx, cy, r, p) && continue
        cx, cy = p
        r = 0.0
        for j in 1:i-1
            q = pts[j]
            _inside(cx, cy, r, q) && continue
            cx = (p[1]+q[1]) / 2
            cy = (p[2]+q[2]) / 2
            r  = sqrt((p[1]-q[1])^2 + (p[2]-q[2])^2) / 2
            for k in 1:j-1
                s = pts[k]
                _inside(cx, cy, r, s) && continue
                cx, cy, r = _circumcircle(p, q, s)
            end
        end
    end
    return (center=(cx, cy), radius=r)
end


"""
    translate(pts::PointList, dx::Real, dy::Real) -> PointList
    translate(pts::PointList, d::Vector) -> PointList

Translate a point list by `(dx, dy)`.

```jldoctest
julia> using Regions

julia> translate([(0.0,0.0),(1.0,0.0)], 2.0, 3.0)
2-element Vector{Tuple{Float64, Float64}}:
 (2.0, 3.0)
 (3.0, 3.0)
```
"""
translate(pts::PointList, dx::Real, dy::Real) =
    PointList([(x + Float64(dx), y + Float64(dy)) for (x, y) in pts])
translate(pts::PointList, d::Vector) = translate(pts, d[1], d[2])
