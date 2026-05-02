#= ------------------------------------------------------------------------

    Morphological operations on Region

    Coordinate convention (column-major, matching Julia arrays):
      Run(column, rows) — vertical segment at a given column.
      Regions are sorted by (column, rows.start).

    Two-level implementation:
      _mink_add / _mink_sub   — raw computation, no complement handling
      _dilation / _erosion    — derived from the raw level
      _minkowski_addition /
      _minkowski_subtraction  — complement-aware, not exported
      erosion / dilation /
      opening / closing / …   — public API

------------------------------------------------------------------------ =#

export erosion, dilation, opening, closing
export morphological_gradient, inner_boundary, outer_boundary
export holes, fill_holes

# Raw computation (no complement handling) -----------------------------------

function _mink_add(a::Region, b::Region)
    isempty(a.runs) && return a
    isempty(b.runs) && return a
    # Commutativity: loop over the region with fewer runs as the "SE"
    if length(b.runs) > length(a.runs)
        return _mink_add(b, a)
    end
    result = Region(Run[])
    for se_run in b.runs
        translated = [_minkowski_addition(r, se_run) for r in a.runs]
        _pack!(translated)
        result = Region(_union(result.runs, translated))
    end
    return result
end

function _mink_sub(a::Region, b::Region)
    isempty(a.runs) && return a
    isempty(b.runs) && return a
    result = a
    for se_run in b.runs
        translated = Run[]
        for r in a.runs   # always iterate original a, not result
            s = _minkowski_subtraction(r, se_run)
            !isempty(s) && push!(translated, s)
        end
        _pack!(translated)
        isempty(translated) && return Region(Run[])
        result = Region(_intersection(result.runs, translated))
    end
    return result
end

_dilation(a::Region, b::Region) = _mink_add(a, invert(b))
_erosion(a::Region,  b::Region) = _mink_sub(a, invert(b))

# Complement-aware (not exported) --------------------------------------------

"""
    _minkowski_addition(a::Region, b::Region)

Compute the Minkowski sum of two regions, with complement handling via
DeMorgan's rules. Both arguments being complements is not supported.
"""
function _minkowski_addition(a::Region, b::Region)
    if a.complement && b.complement
        error("_minkowski_addition: not supported when both regions are complements")
    elseif a.complement
        Region(_mink_sub(Region(a.runs), b).runs, true)
    elseif b.complement
        Region(_mink_sub(Region(b.runs), a).runs, true)
    else
        _mink_add(a, b)
    end
end

"""
    _minkowski_subtraction(a::Region, b::Region)

Compute the Minkowski difference of two regions, with complement handling via
DeMorgan's rules. The structuring element being a complement is not supported.
"""
function _minkowski_subtraction(a::Region, b::Region)
    if a.complement && b.complement
        _mink_sub(Region(b.runs), Region(a.runs))
    elseif a.complement
        Region(_mink_add(Region(a.runs), b).runs, true)
    elseif b.complement
        error("_minkowski_subtraction: structuring element must not be a complement region")
    else
        _mink_sub(a, b)
    end
end

# Public API -----------------------------------------------------------------

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

julia> big = region_from_box(-2, -2, 2, 2);

julia> se  = region_from_box(-1, -1, 1, 1);

julia> erosion(big, se) == se
true

julia> isempty(erosion(Region([Run(0, 0:0)]), se))
true
```
"""
function erosion(a::Region, b::Region)
    if a.complement && b.complement
        _mink_sub(invert(Region(b.runs)), Region(a.runs))
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

julia> small = region_from_box(-1, -1, 1, 1);

julia> se    = region_from_box(-1, -1, 1, 1);

julia> dilation(small, se) == region_from_box(-2, -2, 2, 2)
true
```
"""
function dilation(a::Region, b::Region)
    if a.complement && b.complement
        error("dilation: not supported when both regions are complements")
    elseif a.complement
        Region(_erosion(Region(a.runs), b).runs, true)
    elseif b.complement
        Region(_mink_sub(invert(Region(b.runs)), a).runs, true)
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

julia> big = region_from_box(-2, -2, 2, 2);

julia> se  = region_from_box(-1, -1, 1, 1);

julia> opening(big, se) == big
true

julia> isempty(opening(Region([Run(0, 0:0)]), se))
true
```
"""
opening(a::Region, b::Region) = _minkowski_addition(erosion(a, b), b)

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

julia> se = region_from_box(-1, -1, 1, 1);

julia> c = closing(gapped, se);

julia> contains(c, 0, 0)
true

julia> contains(c, -1, 0) && contains(c, 1, 0)
true
```
"""
closing(a::Region, b::Region) = _minkowski_subtraction(dilation(a, b), b)

"""
    morphological_gradient(a::Region, b::Region)

Morphological gradient: difference of the dilation and erosion of `a` by `b`.

The result is a ring around the boundary of `a`, lying partly inside and
partly outside.

Structuring elements should be centred on the origin.

```jldoctest
julia> using Regions

julia> box = region_from_box(-2, -2, 2, 2);

julia> se  = region_from_box(-1, -1, 1, 1);

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

julia> box = region_from_box(-2, -2, 2, 2);

julia> ib = inner_boundary(box);

julia> contains(ib, -2, 0)
true

julia> contains(ib, 0, 0)
false
```
"""
function inner_boundary(a::Region)
    se = region_from_box(-1, -1, 1, 1)
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

julia> box = region_from_box(-2, -2, 2, 2);

julia> ob = outer_boundary(box);

julia> contains(ob, -3, 0)
true

julia> contains(ob, -2, 0)
false
```
"""
function outer_boundary(a::Region)
    se = region_from_box(-1, -1, 1, 1)
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

julia> frame = difference(region_from_box(-3, -3, 3, 3), region_from_box(-1, -1, 1, 1));

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

julia> frame = difference(region_from_box(-3, -3, 3, 3), region_from_box(-1, -1, 1, 1));

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
