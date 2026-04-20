#= ------------------------------------------------------------------------

    Region

------------------------------------------------------------------------ =#

import Base: copy, -, union, ==, show
export Region
export isempty, ==, copy, invert, -, translate, translate!, center, contains, ∈
export left, top, right, bottom, bounds
export complement
export union, intersection, difference
export region_from_box
export region_from_circle
export region_from_polygon
export region_to_image
export minkowski_addition, minkowski_subtraction
export erosion, dilation, opening, closing
export morphological_gradient, inner_boundary, outer_boundary
export holes, fill_holes

"""
    Region

A region is a discrete set of coordinates in two-dimensional euclidean space.

A region consists of zero or more runs, which are sorted in ascending order.

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

```jldoctest
julia> using Regions

julia> a = Region([Run(0, 0:2), Run(1, 0:2), Run(2, 0:2)]);

julia> b = invert(a)
Region(Run[Run(-2, -2:0), Run(-1, -2:0), Run(0, -2:0)], false)
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
    center(r::Region) -> Region

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

julia> c = center(r);

julia> left(c), right(c), bottom(c), top(c)
(-1, 1, -1, 1)

julia> r2 = Region([Run(10, 5:6), Run(11, 5:6)]);

julia> c2 = center(r2);

julia> left(c2), right(c2)
(-1, 0)
```
"""
function center(r::Region)
    @assert !r.complement && !isempty(r.runs) "center requires a non-empty, non-complement region"
    Δcol = (left(r)   + right(r)) ÷ 2
    Δrow = (bottom(r) + top(r))   ÷ 2
    return translate(r, -Δcol, -Δrow)
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

Calculates the leftmost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function left(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    minimum(run.column for run in r.runs)
end

"""
    top(x::Region)

Calculates the topmost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function top(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    maximum(run.rows.stop for run in r.runs)
end

"""
    right(x::Region)

Calculates the rightmost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function right(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    maximum(run.column for run in r.runs)
end

"""
    bottom(x::Region)

Calculates the bottommost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function bottom(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(r.runs) "cannot calculate for empty regions"
    minimum(run.rows.start for run in r.runs)
end

"""
    bounds(x::Region)

Calculates the left, top, right and bottom region coordinate and returns them
as a tuple.

This function works for non-complement and non-empty regions only.
"""
function bounds(region::Region)
    @assert !region.complement "cannot calculate for infinite (complement) regions"
    @assert !isempty(region.runs) "cannot calculate for empty regions"
    return (minimum(run.column    for run in region.runs),
            maximum(run.rows.stop  for run in region.runs),
            maximum(run.column    for run in region.runs),
            minimum(run.rows.start for run in region.runs))
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
    merge(a::Vector{Run}, b::Vector{Run})

Merge sorted vectors `a` and `b`. Assumes that `a` and `b` are sorted 
and does not check whether `a` or `b` are sorted. 

merge is not exported, since its basic usage is within this file and it conflicts with
a definition in Base.
"""
function merge(a::Vector{Run}, b::Vector{Run})
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
    pack!(a::Vector{Run})

Packs runs together. pack! is not exported, since its basic usage is within this file as a 
building block for union.
"""
function pack!(a::Vector{Run})
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
    union(a::Vector{Run}, b::Vector{Run})

Calculates the union of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function union(a::Vector{Run}, b::Vector{Run})
    res = merge(a, b)
    pack!(res)
    return res
end

"""
    union(a::Region, b::Region)

Calculates the union of two regions. This function supports complement regions and uses 
DeMorgan's rules to eliminate the complement.    
"""
function union(a::Region, b::Region)
    if a.complement && b.complement
        return Region(intersection(a.runs, b.runs), true)
    elseif a.complement
        return Region(difference(a.runs, b.runs), true)
    elseif b.complement
        return Region(difference(b.runs, a.runs), true)
    else
        return Region(union(a.runs, b.runs), false)
    end
end


"""
    intersect!(a::Vector{Run})

Intersects runs. intersect! is not exported, since its basic usage is within this file as a 
building block for intersection.
"""
function intersect!(a::Vector{Run})
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
    intersection(a::Vector{Run}, b::Vector{Run})

Calculates the intersection of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function intersection(a::Vector{Run}, b::Vector{Run})
    res = merge(a, b)
    intersect!(res)
    return res
end

"""
    intersection(a::Region, b::Region)

Calculates the intersection of two regions. This function supports complement regions and uses 
DeMorgan's rules to eliminate the complement.    
"""
function intersection(a::Region, b::Region)
    if a.complement && b.complement
        return Region(union(a.runs, b.runs), true)
    elseif a.complement
        return Region(difference(b.runs, a.runs), false)
    elseif b.complement
        return Region(difference(a.runs, b.runs), false)
    else
        return Region(intersection(a.runs, b.runs), false)
    end
end

"""
    difference(a::Vector{Run}, b::Vector{Run})

Calculates the difference of two sorted vectors of runs. The function assumes that the runs are sorted
but does not check this.
"""
function difference(a::Vector{Run}, b::Vector{Run})
    if isempty(a)
        return Run[]
    end

    if isempty(b)
        return a
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
            for i in first_b:last_b
                if isoverlapping(a[a_index], b[i])
                    # total overlap, erase all of a_run and break
                    if b[i].rows.start <= a[a_index].rows.start && b[i].rows.stop >= a[a_index].rows.stop
                        a[a_index] = Run(a[a_index].column, a[a_index].rows.start:a[a_index].rows.start-1)
                        break;
                    # overlap at start only, shorten a_run at start and continue
                    elseif b[i].rows.start <= a[a_index].rows.start
                        a[a_index] = Run(a[a_index].column, b[i].rows.stop+1:a[a_index].rows.stop)
                    # overlap at end only, shorten a_run at end and continue
                    elseif b[i].rows.stop >= a[a_index].rows.stop
                        a[a_index] = Run(a[a_index].column, a[a_index].rows.start:b[i].rows.start-1)
                    # overlap in the middle, split a_run into two and continue
                    else
                        push!(res, Run(a[a_index].column, a[a_index].rows.start:b[i].rows.start-1))
                        a[a_index] = Run(a[a_index].column, b[i].rows.stop+1:a[a_index].rows.stop)
                    end
                end
            end
            if !isempty(a[a_index])
                push!(res, a[a_index])
            end
        end
    end

    return res
end

"""
    difference(a::Region, b::Region)

Calculates the difference of two regions. This function supports complement regions and uses
DeMorgan's rules to eliminate the complement.
"""
function difference(a::Region, b::Region)
    if a.complement && b.complement
        return Region(difference(b.runs, a.runs), false)
    elseif a.complement
        return Region(union(a.runs, b.runs), true)
    elseif b.complement
        return Region(intersection(a.runs, b.runs), false)
    else
        return Region(difference(a.runs, b.runs), false)
    end
end

"""
    region_from_box(left::Integer, top::Integer, right::Integer, bottom::Integer)

Create a region given box coordinates. The region consists of all coordinates within the box.
"""
function region_from_box(left::Integer, top::Integer, right::Integer, bottom::Integer)
    @assert bottom < top "bottom must be smaller than top"
    @assert left < right "left must be smaller than right"

    region = Region(Run[])
    for col in left:right
        push!(region.runs, Run(col, bottom:top))
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
    region_to_image(r::Region, color=Gray(true))

Converts a region to an image. The function determines the bounds of the
region and then renders the region into the image.

The background of the image is filled with zeroes, the region pixels are
colored with the passed in color.

Some examples of colors that you can pass:
Gray(0.5) : mid gray value
RGB(1, 0, 0) : brightest red value
RGBA(0, 0.5, 0, 0.5) : half transparent mid green value
"""
function region_to_image(region::Region, color=Gray(true))
    (l, t, r, b) = bounds(region)
    img = zeros(typeof(color), t-b+1, r-l+1)
    for run in region.runs
        for row in run.rows
            img[row-b+1, run.column-l+1] = color
        end
    end
    return img
end

"""
    Base.show(io, mime::MIME"image/png", r::Region)

Shows a rich graphical display of a region. The region is displayed in a half 
transparent blue color.
"""
function Base.show(io::IO, mime::MIME"image/png", region::Region)
    if !isempty(region)
        Base.show(io, mime, region_to_image(region, RGBA(0,0,1,0.5)))
    end
end

#= ------------------------------------------------------------------------

    Morphological operations

    Coordinate convention (column-major, matching Julia arrays):
      Run(column, rows) — vertical segment at a given column.
      Regions are sorted by (column, rows.start).

    This mirrors the C++ ngi::region_core which uses horizontal chords
    (row, col_range) sorted row-major. Every formula is structurally
    identical — axes are just swapped.

    Low-level helpers (_minkowski_addition, _minkowski_subtraction,
    _dilation, _erosion) ignore the complement flag and are used as
    building blocks by the public API which handles complement regions
    via DeMorgan's rules.

------------------------------------------------------------------------ =#

# Low-level (no complement handling) ----------------------------------------

function _minkowski_addition(a::Region, b::Region)
    isempty(a.runs) && return a
    isempty(b.runs) && return a
    # Commutativity: loop over the region with fewer runs as the "SE"
    if length(b.runs) > length(a.runs)
        return _minkowski_addition(b, a)
    end
    result = Region(Run[])
    for se_run in b.runs
        translated = [minkowski_addition(r, se_run) for r in a.runs]
        pack!(translated)
        result = Region(union(result.runs, translated))
    end
    return result
end

function _minkowski_subtraction(a::Region, b::Region)
    isempty(a.runs) && return a
    isempty(b.runs) && return a
    result = a
    for se_run in b.runs
        translated = Run[]
        for r in a.runs   # always iterate original a, not result
            s = minkowski_subtraction(r, se_run)
            !isempty(s) && push!(translated, s)
        end
        pack!(translated)
        isempty(translated) && return Region(Run[])
        result = Region(intersection(result.runs, translated))
    end
    return result
end

_dilation(a::Region, b::Region) = _minkowski_addition(a, invert(b))
_erosion(a::Region,  b::Region) = _minkowski_subtraction(a, invert(b))

# Public API with DeMorgan complement handling --------------------------------

"""
    minkowski_addition(a::Region, b::Region)

Compute the Minkowski sum of two regions.

For every point `p` in `a` and `q` in `b`, the result contains `p + q`.
This expands `a` by the shape of `b` (or vice versa — the operation is
commutative).

Complement regions are handled via DeMorgan's rules. Both arguments being
complements simultaneously is not supported and throws an error.

```jldoctest
julia> using Regions

julia> origin = Region([Run(0, 0:0)]);

julia> hbar = Region([Run(-1, 0:0), Run(0, 0:0), Run(1, 0:0)]);

julia> minkowski_addition(origin, hbar)
Region(Run[Run(-1, 0:0), Run(0, 0:0), Run(1, 0:0)], false)

julia> minkowski_addition(hbar, origin) == minkowski_addition(origin, hbar)
true
```
"""
function minkowski_addition(a::Region, b::Region)
    if a.complement && b.complement
        error("minkowski_addition: not supported when both regions are complements")
    elseif a.complement
        Region(_minkowski_subtraction(Region(a.runs), b).runs, true)
    elseif b.complement
        Region(_minkowski_subtraction(Region(b.runs), a).runs, true)
    else
        _minkowski_addition(a, b)
    end
end

"""
    minkowski_subtraction(a::Region, b::Region)

Compute the Minkowski difference (erosion by a structuring element) of two regions.

The result contains every point `c` such that `c + b ⊆ a`.  This shrinks `a`
by the shape of `b`.

Complement regions are handled via DeMorgan's rules. The structuring element
being a complement region is not supported and throws an error.

```jldoctest
julia> using Regions

julia> big = region_from_box(-2, 2, 2, -2);

julia> se  = region_from_box(-1, 1, 1, -1);

julia> minkowski_subtraction(big, se) == se
true
```
"""
function minkowski_subtraction(a::Region, b::Region)
    if a.complement && b.complement
        _minkowski_subtraction(Region(b.runs), Region(a.runs))
    elseif a.complement
        Region(_minkowski_addition(Region(a.runs), b).runs, true)
    elseif b.complement
        error("minkowski_subtraction: structuring element must not be a complement region")
    else
        _minkowski_subtraction(a, b)
    end
end

"""
    erosion(a::Region, b::Region)

Erode region `a` with structuring element `b`.

Erosion shrinks `a`: the result contains every point `c` such that
the reflected (inverted) `b` centred at `c` fits entirely within `a`.
Erosion may split a connected region into disconnected parts.

Structuring elements should be centred on the origin.
Complement regions are handled via DeMorgan's rules.

```jldoctest
julia> using Regions

julia> big = region_from_box(-2, 2, 2, -2);

julia> se  = region_from_box(-1, 1, 1, -1);

julia> erosion(big, se) == se
true

julia> isempty(erosion(Region([Run(0, 0:0)]), se))
true
```
"""
function erosion(a::Region, b::Region)
    if a.complement && b.complement
        _minkowski_subtraction(invert(Region(b.runs)), Region(a.runs))
    elseif a.complement
        Region(_dilation(Region(a.runs), b).runs, true)
    elseif b.complement
        error("erosion: structuring element must not be a complement region")
    else
        _erosion(a, b)
    end
end

"""
    dilation(a::Region, b::Region)

Dilate region `a` with structuring element `b`.

Dilation grows `a`: the result contains every point reachable by placing
`b` centred at any pixel of `a`. Dilation may merge disconnected parts.

Structuring elements should be centred on the origin.
Complement regions are handled via DeMorgan's rules.

```jldoctest
julia> using Regions

julia> small = region_from_box(-1, 1, 1, -1);

julia> se    = region_from_box(-1, 1, 1, -1);

julia> dilation(small, se) == region_from_box(-2, 2, 2, -2)
true
```
"""
function dilation(a::Region, b::Region)
    if a.complement && b.complement
        error("dilation: not supported when both regions are complements")
    elseif a.complement
        Region(_erosion(Region(a.runs), b).runs, true)
    elseif b.complement
        Region(_minkowski_subtraction(invert(Region(b.runs)), a).runs, true)
    else
        _dilation(a, b)
    end
end

"""
    opening(a::Region, b::Region)

Morphological opening: erosion of `a` by `b`, followed by Minkowski addition
with `b`.

Opening removes structures smaller than the structuring element and smoothes
the region boundary. The result is always a subset of `a`.

Structuring elements should be centred on the origin.

```jldoctest
julia> using Regions

julia> big = region_from_box(-2, 2, 2, -2);

julia> se  = region_from_box(-1, 1, 1, -1);

julia> opening(big, se) == big
true

julia> isempty(opening(Region([Run(0, 0:0)]), se))
true
```
"""
opening(a::Region, b::Region) = minkowski_addition(erosion(a, b), b)

"""
    closing(a::Region, b::Region)

Morphological closing: dilation of `a` by `b`, followed by Minkowski
subtraction with `b`.

Closing fills gaps and holes smaller than the structuring element and
smoothes the region boundary. The result always contains `a` as a subset.

Structuring elements should be centred on the origin.

```jldoctest
julia> using Regions

julia> gapped = Region([Run(-1, 0:0), Run(1, 0:0)]);

julia> se = region_from_box(-1, 1, 1, -1);

julia> c = closing(gapped, se);

julia> contains(c, 0, 0)
true

julia> contains(c, -1, 0) && contains(c, 1, 0)
true
```
"""
closing(a::Region, b::Region) = minkowski_subtraction(dilation(a, b), b)

"""
    morphological_gradient(a::Region, b::Region)

Morphological gradient: difference of the dilation and erosion of `a` by `b`.

The result is a ring around the boundary of `a`, lying partly inside and
partly outside.

Structuring elements should be centred on the origin.

```jldoctest
julia> using Regions

julia> box = region_from_box(-2, 2, 2, -2);

julia> se  = region_from_box(-1, 1, 1, -1);

julia> grad = morphological_gradient(box, se);

julia> contains(grad, -2, 0)
true

julia> contains(grad, 0, 0)
false
```
"""
morphological_gradient(a::Region, b::Region) = difference(dilation(a, b), erosion(a, b))

"""
    inner_boundary(a::Region)

Compute the inner boundary of a region.

The inner boundary is the set of pixels that belong to `a` but would be
removed by a 3×3 erosion — i.e. the outermost layer of pixels strictly
inside `a`.

```jldoctest
julia> using Regions

julia> box = region_from_box(-2, 2, 2, -2);

julia> ib = inner_boundary(box);

julia> contains(ib, -2, 0)
true

julia> contains(ib, 0, 0)
false
```
"""
function inner_boundary(a::Region)
    se = region_from_box(-1, 1, 1, -1)
    difference(copy(a), erosion(a, se))
end

"""
    outer_boundary(a::Region)

Compute the outer boundary of a region.

The outer boundary is the set of pixels that do not belong to `a` but are
added by a 3×3 dilation — i.e. the innermost layer of pixels strictly
outside `a`.

```jldoctest
julia> using Regions

julia> box = region_from_box(-2, 2, 2, -2);

julia> ob = outer_boundary(box);

julia> contains(ob, -3, 0)
true

julia> contains(ob, -2, 0)
false
```
"""
function outer_boundary(a::Region)
    se = region_from_box(-1, 1, 1, -1)
    difference(dilation(a, se), a)
end

"""
    holes(region::Region)

Extract the holes of a region.

A hole is a connected component of the complement-within-bounding-box that
does not touch the bounding box boundary. Returns a `Vector{Region}`, one
element per hole.

Only non-complement regions are supported.

```jldoctest
julia> using Regions

julia> frame = difference(region_from_box(-3, 3, 3, -3), region_from_box(-1, 1, 1, -1));

julia> hs = holes(frame);

julia> length(hs)
1

julia> contains(hs[1], 0, 0)
true
```
"""
function holes(region::Region)
    @assert !region.complement "holes: not defined for complement regions"
    isempty(region) && return Region[]
    (l, t, r, b) = bounds(region)
    (l == r || b == t) && return Region[]   # too narrow to enclose a hole
    bbox = region_from_box(l, t, r, b)
    complement_in_box = difference(bbox, region)
    isempty(complement_in_box) && return Region[]
    comps = components(complement_in_box, unsigned(0), unsigned(0))
    return filter(c -> !(left(c) == l || right(c) == r ||
                         bottom(c) == b || top(c) == t), comps)
end

"""
    fill_holes(region::Region)

Fill the holes of a region.

Returns a new region equal to `region` with all enclosed holes filled in.
If the region has no holes the original region is returned unchanged.

Only non-complement regions are supported.

```jldoctest
julia> using Regions

julia> frame = difference(region_from_box(-3, 3, 3, -3), region_from_box(-1, 1, 1, -1));

julia> filled = fill_holes(frame);

julia> contains(filled, 0, 0)
true

julia> contains(filled, -3, 0)
true
```
"""
function fill_holes(region::Region)
    @assert !region.complement "fill_holes: not defined for complement regions"
    hs = holes(region)
    isempty(hs) && return region
    return reduce((a, b) -> union(a, b), hs; init=region)
end

