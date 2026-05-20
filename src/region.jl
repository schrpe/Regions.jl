#= ------------------------------------------------------------------------

    Region

------------------------------------------------------------------------ =#

import Base: copy, -, union, ==, show, hash
export Region
export isempty, ==, copy, invert, -, translate, translate!, center_region, is_centered, contains, ∈
export left, top, right, bottom, bounds
export complement
export union, intersection, difference
export region_from_box
export region_from_circle
export region_from_polygon
export region_from_point_list
export region_from_point
export region_from_line_segment
export region_from_ellipse
export region_from_ring
export region_to_image

"""
    Region

A region is a discrete set of coordinates in two-dimensional euclidean space, represented as
a sorted vector of `Run`s plus a boolean `complement` flag.

# Sort invariant

The runs are sorted first by `column`, then by `rows.start`. Many functions in the package
rely on this invariant — out-of-order runs will silently produce wrong results. If you
mutate `r.runs` directly, restore the order with `sort!(r.runs)` before passing the region
to other functions.

# The `complement` flag

When `complement == false` (the usual case), the runs enumerate the pixels *contained* in
the region. When `complement == true`, the runs enumerate the pixels *excluded* from an
otherwise infinite plane — i.e. the region is the set-theoretic complement of those runs.
This flag is what allows the package to represent infinite regions (such as the result of
inverting a finite region) without storing infinite memory, and it is what enables `union`,
`intersection`, and `difference` to handle complement operands correctly via De Morgan's
laws. Use [`complement`](@ref) to construct a complement region rather than setting the
field directly.

# Examples

```jldoctest reg
julia> using Regions

julia> Region() # create an empty region
Region(Run[], false)

julia> Region([Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)]) # create a region with 3 runs
Region(Run[Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)], false)

julia> Region([Run(col, -10:10) for col=-10:10]); # create a region with many runs using comprehension
```
"""
struct Region
    runs::Vector{Run}
    complement::Bool
end

Region(runs::Vector{Run}) = Region(runs, false)
Region() = Region(Run[], false)

"""
    isempty(x::Region)

Discover whether the region is empty.

```jldoctest
julia> using Regions

julia> isempty(Region(Run[]))
true

julia> isempty(Region([Run(2, 1:1)]))
false
```
"""
isempty(x::Region) = isempty(x.runs)

"""
    ==(a::Region, b::Region)

Equality operator for two regions. Two regions are equal, if both their runs and their 
complement flags are equal.

```jldoctest
julia> using Regions

julia> a = Region([Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)]);

julia> b = Region([Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)]);

julia> a == b
true
```
"""
==(a::Region, b::Region) = a.runs == b.runs && a.complement == b.complement

"""
    hash(r::Region, h::UInt) -> UInt

Hash a region by combining the hashes of its `runs` vector and `complement` flag.
Consistent with `==`: regions that compare equal hash equal, so `Region`s can be
used as keys in `Dict` / `Set`.

```jldoctest
julia> using Regions

julia> a = Region([Run(0, 0:2), Run(1, 0:2)]);

julia> b = Region([Run(0, 0:2), Run(1, 0:2)]);

julia> hash(a) == hash(b)
true

julia> d = Dict(a => "first"); d[b]
"first"
```
"""
hash(r::Region, h::UInt) = hash(r.complement, hash(r.runs, h))

"""
    copy(x::Region)
    
Create a copy of a region.    

```jldoctest
julia> using Regions

julia> a = Region([Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)]);

julia> b = copy(a)
Region(Run[Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)], false)
```
"""
copy(x::Region) = Region(copy(x.runs), x.complement)

"""
    invert(x::Region)
    -(x::Region)

Invert a region. Inversion mirrors a region at the origin. A region is inverted
by inverting each of its runs. Since the runs of a region are sorted by their column and
row coordinates, the order of the runs is inversed as well.

In addition to the invert method, you can also use the unary - operator.

```jldoctest
julia> using Regions

julia> a = Region([Run(0, 0:2), Run(1, 0:2), Run(2, 0:2)]);

julia> b = invert(a)
Region(Run[Run(-2, -2:0), Run(-1, -2:0), Run(0, -2:0)], false)

julia> c = -(a)
Region(Run[Run(-2, -2:0), Run(-1, -2:0), Run(0, -2:0)], false)

julia> a == invert(-a)
true
```
"""
function invert(x::Region)
    result = Region(Run[], x.complement)
    # iterating backwards maintains the correct sort order of the runs
    for i in length(x.runs):-1:1
        push!(result.runs, -x.runs[i])
    end
    return result
end
-(x::Region) = invert(x)

"""
    translate(r::Region, x::Integer, y::Integer)
    translate(r::Region, a::Vector{Int})

Translate a region. Translation moves a region. A region is translated by translating each 
of its runs. 

In addition to the translate method, you can also use the + or - operators
to translate a region.

```jldoctest
julia> using Regions

julia> a = Region([Run(0, 0:2), Run(1, 0:2), Run(2, 0:2)]);

julia> b = translate(a, -1, -1)
Region(Run[Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)], false)
```
"""
function translate(r::Region, x::Integer, y::Integer)
    return translate!(copy(r), x, y)
end
translate(r::Region, d::Vector{Int}) = translate(r, d[1], d[2])
+(x::Region, y::Vector{Int}) = translate(x, y[1], y[2])
+(x::Vector{Int}, y::Region) = translate(y, x[1], x[2])
-(x::Region, y::Vector{Int}) = translate(x, -y[1], -y[2])
function translate!(r::Region, x::Integer, y::Integer)
    for i in 1:length(r.runs)
        r.runs[i] = translate(r.runs[i], x, y)
    end
    return r
end
translate!(r::Region, d::Vector{Int}) = translate!(r, d[1], d[2])

"""
    center_region(r::Region) -> Region

Translate a non-empty, non-complement region so that its bounding-box centre
lands as close to the origin as possible.

The translation amounts are computed from the integer midpoints of the column
and row extents:

    Δcol = (left(r) + right(r))  ÷ 2
    Δrow = (bottom(r) + top(r))  ÷ 2

Because pixel coordinates are integers, even-width or even-height regions
cannot be placed symmetrically; the standard integer (floor) division places
the origin one pixel left of / below the geometric centre in those cases.

```jldoctest
julia> using Regions

julia> r = Region([Run(3, 2:4), Run(4, 2:4), Run(5, 2:4)]);

julia> c = center_region(r);

julia> left(c), right(c), bottom(c), top(c)
(-1, 1, 1, -1)
```
"""
function center_region(r::Region)
    @assert !r.complement && !isempty(r.runs) "center requires a non-empty, non-complement region"
    Δcol = (left(r)   + right(r)) ÷ 2
    Δrow = (bottom(r) + top(r))   ÷ 2
    return translate(r, -Δcol, -Δrow)
end

"""
    is_centered(r::Region) -> Bool

Return `true` if the bounding-box midpoint of `r` is already at the origin,
i.e. if [`center_region`](@ref) would leave `r` unchanged.

Uses the same integer midpoint arithmetic as `center_region`:
`Δcol = (left + right) ÷ 2`, `Δrow = (bottom + top) ÷ 2`.

```jldoctest
julia> using Regions

julia> is_centered(Region([Run(-1, -1:1), Run(0, -1:1), Run(1, -1:1)]))
true

julia> is_centered(Region([Run(3, 2:4), Run(4, 2:4), Run(5, 2:4)]))
false

julia> is_centered(center_region(Region([Run(3, 2:4), Run(4, 2:4), Run(5, 2:4)])))
true
```
"""
function is_centered(r::Region)
    @assert !r.complement && !isempty(r.runs) "is_centered requires a non-empty, non-complement region"
    (left(r) + right(r)) ÷ 2 == 0 && (bottom(r) + top(r)) ÷ 2 == 0
end

"""
    contains(r::Region, x::Integer, y::Integer)
    contains(r::Region, a::Vector{Int})

Test if region r contains position (x, y). x is the column coordinate, y is the row coordinate.

```jldoctest
julia> using Regions

julia> r = Region([Run(2, 1:4)]);

julia> contains(r, 2, 3)
true

julia> contains(r, 2, 5)
false

julia> contains(r, 3, 3)
false

julia> [2, 3] ∈ r
true
```
"""
contains(r::Region, x::Integer, y::Integer) = r.complement ? !any(run -> contains(run, x, y), r.runs) : any(run -> contains(run, x, y), r.runs)
contains(r::Region, a::Vector{Int}) = contains(r, a[1], a[2])
∈(a::Vector{Int}, r::Region) = contains(r, a)

"""
    left(x::Region)

Returns the smallest column coordinate of `x` — its leftmost column.

Only valid for non-complement, non-empty regions.

```jldoctest
julia> using Regions

julia> left(region_from_box(2, 1, 7, 5))
2
```
"""
function left(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    minimum(run.column for run in r.runs)
end

"""
    top(x::Region)

Returns the smallest row coordinate of `x`. Under the image-coordinate convention used by
the package this is the topmost row of the region (the row with the smallest index).

Only valid for non-complement, non-empty regions.

```jldoctest
julia> using Regions

julia> top(region_from_box(2, 1, 7, 5))
1
```
"""
function top(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    minimum(run.rows.start for run in r.runs)
end

"""
    right(x::Region)

Returns the largest column coordinate of `x` — its rightmost column.

Only valid for non-complement, non-empty regions.

```jldoctest
julia> using Regions

julia> right(region_from_box(2, 1, 7, 5))
7
```
"""
function right(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    maximum(run.column for run in r.runs)
end

"""
    bottom(x::Region)

Returns the largest row coordinate of `x`. Under the image-coordinate convention used by
the package this is the bottommost row of the region (the row with the largest index).

Only valid for non-complement, non-empty regions.

```jldoctest
julia> using Regions

julia> bottom(region_from_box(2, 1, 7, 5))
5
```
"""
function bottom(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    maximum(run.rows.stop for run in r.runs)
end

"""
    bounds(x::Region)

Returns the bounding box of `x` as `(left, top, right, bottom)` — equivalently
`(min column, min row, max column, max row)`. Under the image-coordinate convention used by
the package, `top < bottom` (rows increase downward).

Only valid for non-complement, non-empty regions.

```jldoctest
julia> using Regions

julia> bounds(region_from_box(2, 1, 7, 5))
(2, 1, 7, 5)
```
"""
function bounds(region::Region)
    @assert !region.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(region.runs) "cannot calculate for empty regions"
    return (minimum(run.column for run in region.runs),
            minimum(run.rows.start for run in region.runs),
            maximum(run.column for run in region.runs),
            maximum(run.rows.stop for run in region.runs))
end

"""
    complement(x::Region)

Calculates the set-theoretic complement of a region.

With a non-complemented region, the runs specify the contained pixels, i.e. they specify
what is included within the region. With a complemented region, the runs specify the
non-contained pixels, i.e. they specify what is not included within the region.

```jldoctest
julia> using Regions

julia> r = Region([Run(0, 0:5)]);

julia> c = complement(r);

julia> c.complement
true

julia> contains(r, 0, 3)
true

julia> contains(c, 0, 3)
false

julia> contains(c, 0, 9)
true
```
"""
complement(x::Region) = Region(copy(x.runs), !x.complement)

"""
    _merge(a::Vector{Run}, b::Vector{Run})

Merge sorted vectors `a` and `b`. Assumes that `a` and `b` are sorted
and does not check whether `a` or `b` are sorted.
"""
function _merge(a::Vector{Run}, b::Vector{Run})
    res = Run[]
    i = 1
    j = 1
    while i <= length(a)
        if j > length(b)
            while i <= length(a)
                push!(res, a[i])
                i = i+1
            end
            return res
        end
        if (b[j] < a[i])
            push!(res, b[j])
            j = j+1
        else
            push!(res, a[i])
            i = i+1
        end
    end
    while j <= length(b)
        push!(res, b[j])
        j = j+1
    end
    return res
end


"""
    _pack!(a::Vector{Run})

Pack consecutive runs in the same column that touch or overlap into a single run.
"""
function _pack!(a::Vector{Run})
    read = 1
    write = 1

    while read <= length(a)
        a[write] = a[read]
        read += 1

        while read <= length(a) && a[write].column == a[read].column && a[write].rows.stop + 1 >= a[read].rows.start
            if a[read].rows.stop > a[write].rows.stop
                a[write] = Run(a[read].column, a[write].rows.start:a[read].rows.stop)
            end
            read += 1
        end
        write += 1
    end
    deleteat!(a, write:length(a))
end

"""
    _union(a::Vector{Run}, b::Vector{Run})

Calculate the union of two sorted arrays of runs.
"""
function _union(a::Vector{Run}, b::Vector{Run})
    res = _merge(a, b)
    _pack!(res)
    return res
end

"""
    union(a::Region, b::Region)

Returns the set-theoretic union of `a` and `b` — every pixel contained in `a`, in `b`, or in
both. The operation is commutative and associative.

Complement regions are handled transparently: any combination of regular and complement
operands is mapped via De Morgan's laws to operations on regular runs, and the result is
returned with the appropriate `complement` flag.

```jldoctest
julia> using Regions

julia> a = region_from_box(0, 0, 4, 3);

julia> b = region_from_box(3, 2, 7, 5);

julia> area(union(a, b))
36
```
"""
function union(a::Region, b::Region)
    if a.complement && b.complement
        return Region(_intersection(a.runs, b.runs), true)
    elseif a.complement
        return Region(_difference(a.runs, b.runs), true)
    elseif b.complement
        return Region(_difference(b.runs, a.runs), true)
    else
        return Region(_union(a.runs, b.runs), false)
    end
end


"""
    _intersect!(a::Vector{Run})

Reduce a sorted array of runs to only the pairwise-intersecting portions.
"""
function _intersect!(a::Vector{Run})
    read = 1
    if read > length(a)
        return
    end
    next = read + 1
    write = read
    while next <= length(a)
        if a[read].column != a[next].column
            read = next
            next += 1
        else
            if a[next].rows.start > a[read].rows.stop
                read = next
                next += 1
            else
                a[write] = Run(a[read].column, a[next].rows.start:min(a[read].rows.stop, a[next].rows.stop))
                if a[next].rows.stop < a[read].rows.stop
                    a[next] = a[read]
                end
                read = next
                next += 1
                write += 1
            end
        end
    end
    deleteat!(a, write:length(a))
end

"""
    _intersection(a::Vector{Run}, b::Vector{Run})

Calculate the intersection of two sorted arrays of runs.
"""
function _intersection(a::Vector{Run}, b::Vector{Run})
    res = _merge(a, b)
    _intersect!(res)
    return res
end

"""
    intersection(a::Region, b::Region)

Returns the set-theoretic intersection of `a` and `b` — only the pixels contained in both.
Useful for masking: intersect a segmented region with a geometric region of interest (a box,
circle, polygon, …) to restrict subsequent analysis to that area.

Complement regions are handled transparently via De Morgan's laws.

```jldoctest
julia> using Regions

julia> a = region_from_box(0, 0, 4, 3);

julia> b = region_from_box(3, 2, 7, 5);

julia> area(intersection(a, b))
4
```
"""
function intersection(a::Region, b::Region)
    if a.complement && b.complement
        return Region(_union(a.runs, b.runs), true)
    elseif a.complement
        return Region(_difference(b.runs, a.runs), false)
    elseif b.complement
        return Region(_difference(a.runs, b.runs), false)
    else
        return Region(_intersection(a.runs, b.runs), false)
    end
end

"""
    _difference(a::Vector{Run}, b::Vector{Run})

Calculate the difference of two sorted vectors of runs (elements in `a` not in `b`).
"""
function _difference(a::Vector{Run}, b::Vector{Run})
    if isempty(a)
        return Run[]
    end

    if isempty(b)
        return copy(a)
    end

    res = Run[]

    # first_b and last_b form a range of runs in b that are in the same column
    first_b = findfirst(x -> x.column >= a[1].column, b)
    last_b = first_b
    if !isnothing(first_b)
        idx = findlast(x -> x.column == b[first_b].column, view(b, first_b:length(b)))
        last_b = isnothing(idx) ? first_b : first_b + idx - 1
    end

    for a_index in 1:length(a)
        if !isnothing(first_b) && a[a_index].column > b[first_b].column
            # update the range — start search from current first_b since both arrays are sorted
            old_first_b = first_b
            idx = findfirst(x -> x.column >= a[a_index].column, view(b, old_first_b:length(b)))
            first_b = isnothing(idx) ? nothing : old_first_b + idx - 1
            last_b = first_b
            if !isnothing(first_b)
                idx2 = findlast(x -> x.column == b[first_b].column, view(b, first_b:length(b)))
                last_b = isnothing(idx2) ? first_b : first_b + idx2 - 1
            end
        end
        if isnothing(first_b) || a[a_index].column != b[first_b].column
            push!(res, a[a_index])
        else
            a_run = a[a_index]  # local copy — never mutate the input vector
            for i in first_b:last_b
                if isoverlapping(a_run, b[i])
                    # total overlap, erase all of a_run and break
                    if b[i].rows.start <= a_run.rows.start && b[i].rows.stop >= a_run.rows.stop
                        a_run = Run(a_run.column, a_run.rows.start:a_run.rows.start-1)
                        break
                    # overlap at start only, shorten a_run at start and continue
                    elseif b[i].rows.start <= a_run.rows.start
                        a_run = Run(a_run.column, b[i].rows.stop+1:a_run.rows.stop)
                    # overlap at end only, shorten a_run at end and continue
                    elseif b[i].rows.stop >= a_run.rows.stop
                        a_run = Run(a_run.column, a_run.rows.start:b[i].rows.start-1)
                    # overlap in the middle, split a_run into two and continue
                    else
                        push!(res, Run(a_run.column, a_run.rows.start:b[i].rows.start-1))
                        a_run = Run(a_run.column, b[i].rows.stop+1:a_run.rows.stop)
                    end
                end
            end
            if !isempty(a_run)
                push!(res, a_run)
            end
        end
    end

    return res
end

"""
    difference(a::Region, b::Region)

Returns the set-theoretic difference `a \\ b` — every pixel contained in `a` but *not* in `b`.
The operation is asymmetric: `difference(a, b)` and `difference(b, a)` are generally
different regions.

Complement regions are handled transparently via De Morgan's laws.

```jldoctest
julia> using Regions

julia> a = region_from_box(0, 0, 4, 3);

julia> b = region_from_box(3, 2, 7, 5);

julia> area(difference(a, b))
16

julia> area(difference(b, a))
16
```
"""
function difference(a::Region, b::Region)
    if a.complement && b.complement
        return Region(_difference(b.runs, a.runs), false)
    elseif a.complement
        return Region(_union(a.runs, b.runs), true)
    elseif b.complement
        return Region(_intersection(a.runs, b.runs), false)
    else
        return Region(_difference(a.runs, b.runs), false)
    end
end

"""
    region_from_box(left::Integer, top::Integer, right::Integer, bottom::Integer)

Create a filled rectangular region from its bounding-box coordinates. The argument order is
`left, top, right, bottom`, and the package's image-coordinate convention requires
`top < bottom` and `left < right` (rows increase downward, columns increase to the right).
The result contains one vertical run per column, each spanning rows `top:bottom`.

```jldoctest
julia> using Regions

julia> r = region_from_box(1, 1, 3, 4);

julia> bounds(r)
(1, 1, 3, 4)

julia> area(r)
12
```
"""
function region_from_box(left::Integer, top::Integer, right::Integer, bottom::Integer)
    @assert top < bottom "top must be smaller than bottom"
    @assert left < right "left must be smaller than right"

    region = Region(Run[])
    for col in left:right
        push!(region.runs, Run(col, top:bottom))
    end
    return region
end

"""
    region_from_circle(cx::Integer, cy::Integer, radius::Integer)

Create a filled circular region with center `(cx, cy)` and the given `radius`.

All integer coordinates `(x, y)` satisfying `(x − cx)² + (y − cy)² ≤ radius²` are
included. Integer square root is used to avoid floating-point rounding issues.

```jldoctest
julia> using Regions

julia> region_from_circle(0, 0, 0)
Region(Run[Run(0, 0:0)], false)

julia> region_from_circle(0, 0, 2)
Region(Run[Run(-2, 0:0), Run(-1, -1:1), Run(0, -2:2), Run(1, -1:1), Run(2, 0:0)], false)

julia> contains(region_from_circle(0, 0, 5), 0, 5)
true

julia> contains(region_from_circle(0, 0, 5), 4, 4)
false
```
"""
function region_from_circle(cx::Integer, cy::Integer, radius::Integer)
    @assert radius >= 0 "radius must be non-negative"
    region = Region(Run[])
    for col in (cx - radius):(cx + radius)
        dx = col - cx
        dy = isqrt(radius^2 - dx^2)
        push!(region.runs, Run(col, (cy - dy):(cy + dy)))
    end
    return region
end

"""
    region_from_polygon(vertices::Vector{Tuple{Int,Int}})

Create a filled region from a polygon defined by its `vertices` as `(column, row)` pairs,
given in either clockwise or counter-clockwise order.

The fill uses the half-open interval convention: for each edge the column with the smaller
x-coordinate is included and the column with the larger x-coordinate is excluded. As a
result, the rightmost column of the polygon is not filled. Horizontal edges are ignored.

```jldoctest
julia> using Regions

julia> r = region_from_polygon([(0,0), (4,0), (2,4)]);

julia> length(r.runs)
4

julia> r.runs
4-element Vector{Run}:
 Run(0, 0:0)
 Run(1, 0:2)
 Run(2, 0:4)
 Run(3, 0:2)

julia> contains(r, 2, 2)
true

julia> contains(r, 0, 2)
false
```
"""
function region_from_polygon(vertices::Vector{Tuple{Int,Int}})
    n = length(vertices)
    @assert n >= 3 "polygon must have at least 3 vertices"

    col_min = minimum(v[1] for v in vertices)
    col_max = maximum(v[1] for v in vertices)

    region = Region(Run[])

    for col in col_min:col_max
        ys = Float64[]
        for i in 1:n
            x1, y1 = vertices[i]
            x2, y2 = vertices[mod1(i + 1, n)]
            if min(x1, x2) <= col < max(x1, x2)
                t = (col - x1) / (x2 - x1)
                push!(ys, y1 + t * (y2 - y1))
            end
        end
        sort!(ys)
        for i in 1:2:length(ys) - 1
            y_start = ceil(Int, ys[i])
            y_end   = floor(Int, ys[i + 1])
            if y_start <= y_end
                push!(region.runs, Run(col, y_start:y_end))
            end
        end
    end

    return region
end

"""
    region_from_point_list(points::Vector{Tuple{Int,Int}})

Create a region from a list of integer pixel coordinates `(column, row)`.
Each point becomes one pixel; duplicate points are merged.

```jldoctest
julia> using Regions

julia> r = region_from_point_list([(0,0),(1,0),(1,1)]);

julia> area(r)
3

julia> contains(r, 1, 1)
true
```
"""
function region_from_point_list(points::Vector{Tuple{Int,Int}})
    isempty(points) && return Region(Run[])
    runs = [Run(x, y:y) for (x, y) in points]
    sort!(runs)
    _pack!(runs)
    return Region(runs)
end

"""
    region_from_point(x::Real, y::Real)

Create a single-pixel region at the nearest integer coordinate to `(x, y)`.
Rounding uses `trunc(Int, v + 0.5)`, matching C++ `(int)(v + 0.5)`.

```jldoctest
julia> using Regions

julia> r = region_from_point(1.4, 2.6);

julia> area(r)
1

julia> contains(r, 1, 3)
true
```
"""
function region_from_point(x::Real, y::Real)
    ix = trunc(Int, Float64(x) + 0.5)
    iy = trunc(Int, Float64(y) + 0.5)
    return Region([Run(ix, iy:iy)])
end

"""
    region_from_line_segment(x0::Real, y0::Real, x1::Real, y1::Real)

Create a region containing all pixels on the 8-connected Bresenham line
from `(x0, y0)` to `(x1, y1)`. Endpoints are rounded to the nearest integer.

```jldoctest
julia> using Regions

julia> area(region_from_line_segment(0.0, 0.0, 3.0, 0.0))
4

julia> area(region_from_line_segment(0.0, 0.0, 0.0, 3.0))
4

julia> area(region_from_line_segment(2.0, 2.0, 2.0, 2.0))
1
```
"""
function region_from_line_segment(x0::Real, y0::Real, x1::Real, y1::Real)
    ix0 = round(Int, x0); iy0 = round(Int, y0)
    ix1 = round(Int, x1); iy1 = round(Int, y1)
    runs = Run[]
    dx = abs(ix1 - ix0)
    dy = abs(iy1 - iy0)
    sx = sign(ix1 - ix0)
    sy = sign(iy1 - iy0)
    err = dx - dy
    x, y = ix0, iy0
    while true
        push!(runs, Run(x, y:y))
        x == ix1 && y == iy1 && break
        e2 = 2 * err
        if e2 > -dy
            err -= dy
            x += sx
        end
        if e2 < dx
            err += dx
            y += sy
        end
    end
    sort!(runs)
    _pack!(runs)
    return Region(runs)
end

"""
    region_from_ellipse(cx, cy, rx, ry, phi)
    region_from_ellipse(e::NamedTuple)

Create a filled region from an ellipse with center `(cx, cy)`, semi-axes `rx` (along `phi`)
and `ry` (perpendicular), and rotation angle `phi` in radians.

The second form accepts a named tuple `(center, semi_axes, angle)` as returned by
[`equivalent_ellipse`](@ref), enabling round-trip conversion.

```jldoctest
julia> using Regions

julia> r = region_from_ellipse(0.0, 0.0, 2.0, 1.0, 0.0);

julia> area(r)
4

julia> contains(r, 0, 0)
true
```
"""
function region_from_ellipse(cx::Real, cy::Real, rx::Real, ry::Real, phi::Real)
    cx, cy, rx, ry, phi = Float64.((cx, cy, rx, ry, phi))

    aprime = rx * cos(phi)
    bprime = -ry * sin(phi)
    a      = rx * sin(phi)
    b      = -ry * cos(phi)

    rprime    = sqrt(aprime^2 + bprime^2)
    alphaprime = atan(bprime, aprime)

    x_left  = ceil(Int, cx - rprime)
    x_right = ceil(Int, cx + rprime)

    region = Region(Run[])
    for x in x_left:x_right-1
        cr = (x - cx) / rprime
        abs(cr) >= 1.0 && continue

        rho    = acos(cr)
        theta1 = alphaprime - rho
        theta2 = alphaprime + rho

        y1f = cy + a * cos(theta1) - b * sin(theta1)
        y2f = cy + a * cos(theta2) - b * sin(theta2)
        y1, y2 = ceil(Int, min(y1f, y2f)), ceil(Int, max(y1f, y2f))

        y2 - y1 > 0 && push!(region.runs, Run(x, y1:y2-1))
    end
    return region
end

function region_from_ellipse(e::NamedTuple)
    region_from_ellipse(e.center[1], e.center[2], e.semi_axes[1], e.semi_axes[2], e.angle)
end

"""
    region_from_ring(cx::Integer, cy::Integer, outer_radius::Integer, inner_radius::Integer)

Create a ring-shaped region: the set difference of two concentric circles with the same
center `(cx, cy)`. `outer_radius` must be ≥ `inner_radius` ≥ 0.

```jldoctest
julia> using Regions

julia> r = region_from_ring(0, 0, 5, 3);

julia> area(r) == area(region_from_circle(0, 0, 5)) - area(region_from_circle(0, 0, 3))
true
```
"""
function region_from_ring(cx::Integer, cy::Integer, outer_radius::Integer, inner_radius::Integer)
    @assert outer_radius >= inner_radius >= 0 "outer_radius must be ≥ inner_radius ≥ 0"
    return difference(region_from_circle(cx, cy, outer_radius), region_from_circle(cx, cy, inner_radius))
end

"""
    region_to_image(r::Region, color=Gray(true))

Render a region to a 2D `Array` whose element type matches `color`. The image is sized to
the region's bounding box: `(bottom - top + 1, right - left + 1)` rows by columns. Pixels
outside the region are zero (e.g. `Gray(0)`, `RGB(0,0,0)`, or `RGBA(0,0,0,0)`); pixels
inside are set to `color`. The element type of the returned array is `typeof(color)`, so
calling with `Gray`, `RGB`, or `RGBA` selects the output format.

Some examples of colors you can pass:
- `Gray(0.5)` — mid gray
- `RGB(1, 0, 0)` — bright red
- `RGBA(0, 0.5, 0, 0.5)` — half-transparent mid green

Use this when you need a raster image (for saving, displaying, or interop with image
libraries). For inline display in REPL/notebook contexts the `Base.show` method registered
for `MIME"image/png"` calls this function automatically with a half-transparent blue color.
"""
function region_to_image(region::Region, color=Gray(true))
    (l, t, r, b) = bounds(region)
    img = zeros(typeof(color), b-t+1, r-l+1)
    for run in region.runs
        for row in run.rows
            img[row-t+1, run.column-l+1] = color
        end
    end
    return img
end

"""
    Base.show(io, mime::MIME"image/png", r::Region)

`MIME"image/png"` show method for a `Region`. Renders the region as a PNG via
[`region_to_image`](@ref) with a half-transparent blue color (`RGBA(0, 0, 1, 0.5)`). This is
what produces an inline graphic when a region is the value of the last expression in
notebook environments such as Pluto, Jupyter, or VS Code, or when a region is passed to
`display`. Empty regions render to nothing.
"""
function Base.show(io::IO, mime::MIME"image/png", region::Region)
    if !isempty(region)
        Base.show(io, mime, region_to_image(region, RGBA(0,0,1,0.5)))
    end
end

