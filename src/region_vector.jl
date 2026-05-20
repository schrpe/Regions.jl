#= ------------------------------------------------------------------------

    Vector{Region}

------------------------------------------------------------------------ =#

export left, top, right, bottom, bounds
export regions_to_image
export erosion, dilation, opening, closing
export morphological_gradient, inner_boundary, outer_boundary
export fill_holes
export set_union, set_intersection, filter_area

"""
    left(x::Vector{Region})

Calculates the leftmost coordinate of a vector of regions.
Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> left([Region([Run(2, 1:3)]), Region([Run(7, 1:3)])])
2

julia> ismissing(left(Region[]))
true
```
"""
function left(regions::Vector{Region})
    if !isempty(regions)
        l = left(regions[1])
        for region in regions
            l = min(l, left(region))
        end
        return l
    else
        return missing
    end
end

"""
    top(x::Vector{Region})

Calculates the minimum row coordinate across a vector of regions — the topmost row under
the package's image-coordinate convention.
Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> top([Region([Run(2, 1:3)]), Region([Run(7, 2:6)])])
1

julia> ismissing(top(Region[]))
true
```
"""
function top(regions::Vector{Region})
    if !isempty(regions)
        t = top(regions[1])
        for region in regions
            t = min(t, top(region))
        end
        return t
    else
        return missing
    end
end

"""
    right(x::Vector{Region})

Calculates the rightmost coordinate of a vector of regions.
Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> right([Region([Run(2, 1:3)]), Region([Run(7, 1:3)])])
7

julia> ismissing(right(Region[]))
true
```
"""
function right(regions::Vector{Region})
    if !isempty(regions)
        r = right(regions[1])
        for region in regions
            r = max(r, right(region))
        end
        return r
    else
        return missing
    end
end

"""
    bottom(x::Vector{Region})

Calculates the maximum row coordinate across a vector of regions — the bottommost row under
the package's image-coordinate convention.
Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> bottom([Region([Run(2, 1:3)]), Region([Run(7, 5:8)])])
8

julia> ismissing(bottom(Region[]))
true
```
"""
function bottom(regions::Vector{Region})
    if !isempty(regions)
        b = bottom(regions[1])
        for region in regions
            b = max(b, bottom(region))
        end
        return b
    else
        return missing
    end
end

"""
    bounds(x::Vector{Region})

Calculates `(left, top, right, bottom)` — the minimum column, minimum row, maximum column,
and maximum row — across all regions in the vector. Under the image-coordinate convention,
`top < bottom`. Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> bounds([Region([Run(2, 1:3)]), Region([Run(7, 2:6)])])
(2, 1, 7, 6)

julia> ismissing(bounds(Region[]))
true
```
"""
function bounds(regions::Vector{Region})
    if !isempty(regions)
        l = left(regions[1])
        t = top(regions[1])
        r = right(regions[1])
        b = bottom(regions[1])
        for region in regions
            l = min(l, left(region))
            t = min(t, top(region))
            r = max(r, right(region))
            b = max(b, bottom(region))
        end
        return l, t, r, b
    else
        return missing
    end
end

"""
    regions_to_image(regions::Vector{Region}, colors=[Gray(true)])

Render a vector of regions to a single 2D `Array` sized to the combined bounding box. Each
region is drawn in turn, taking its color from `colors`; when there are more regions than
colors, the color list is cycled. Where two regions overlap, the previously drawn pixel is
alpha-composited under the new pixel — pass colors with `< 1` alpha (e.g. `RGBA`) to make
overlaps visible.

This is the natural rendering for the output of [`components`](@ref), where each connected
blob can be tinted differently.

Some examples of color lists you can pass:
- `[Gray(0.5)]` — flat mid gray for every region
- `[RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1)]` — cycle red/green/blue per region
- `[RGBA(0, 0.5, 0, 0.5), RGBA(0.5, 0, 0, 0.5)]` — half-transparent green and red

Compare with [`region_to_image`](@ref), which renders a single `Region` with a single color.
"""
function regions_to_image(regions::Vector{Region}, colors=[Gray(true)])
    (l, t, r, b) = bounds(regions)
    img = zeros(eltype(colors), b-t+1, r-l+1)
    n = 1
    for region in regions
        for run in region.runs
            for row in run.rows
                ca = color(colors[n])
                aa = alpha(colors[n])
                cb = color(img[row-t+1, run.column-l+1])
                ab = alpha(img[row-t+1, run.column-l+1])
                ac = aa + (1 - aa) * ab
                cc = (aa * ca + (1 - aa) * ab * cb) / ac
                img[row-t+1, run.column-l+1] = eltype(colors)(cc, ac)
            end
        end
        n = mod1(n + 1, length(colors))
    end
    return img
end

"""
    Base.show(io, mime::MIME"image/png", regions::Vector{Region})

`MIME"image/png"` show method for a `Vector{Region}`. Renders the components as a PNG via
[`regions_to_image`](@ref), cycling through six half-transparent colors (blue, green, red,
cyan, magenta, yellow) so that adjacent components are visually distinct. This is what
produces inline graphics for the result of [`components`](@ref) in notebook environments.
"""
function Base.show(io::IO, mime::MIME"image/png", regions::Vector{Region})
    colors = RGBA[RGBA(0,0,1,0.5), RGBA(0,1,0,0.5), RGBA(1,0,0,0.5), RGBA(0,1,1,0.5), RGBA(1,0,1,0.5), RGBA(1,1,0,0.5)]
    Base.show(io, mime, regions_to_image(regions, colors))
end

#= ------------------------------------------------------------------------

    Morphological operations on Vector{Region}

    Each function applies the corresponding scalar operation to every region
    in the vector and collects the non-empty results.

------------------------------------------------------------------------ =#

function _morph_map(f, regions::Vector{Region})
    result = Region[]
    for r in regions
        out = f(r)
        !isempty(out) && push!(result, out)
    end
    return result
end

"""
    _minkowski_addition(regions::Vector{Region}, se::Region)

Apply [`_minkowski_addition`](@ref) to each region in `regions` with structuring
element `se`, returning a new vector that contains only the non-empty results.
"""
_minkowski_addition(regions::Vector{Region}, se::Region) =
    _morph_map(r -> _minkowski_addition(r, se), regions)

"""
    _minkowski_subtraction(regions::Vector{Region}, se::Region)

Apply [`_minkowski_subtraction`](@ref) to each region in `regions` with
structuring element `se`, returning a new vector that contains only the
non-empty results.
"""
_minkowski_subtraction(regions::Vector{Region}, se::Region) =
    _morph_map(r -> _minkowski_subtraction(r, se), regions)

"""
    erosion(regions::Vector{Region}, se::Region)

Apply [`erosion`](@ref) to each region in `regions` with structuring element
`se`, returning a new vector that contains only the non-empty results.

```jldoctest
julia> using Regions

julia> regions = [region_from_box(-2, -2, 2, 2), Region([Run(0, 0:0)])];

julia> se = region_from_box(-1, -1, 1, 1);

julia> length(erosion(regions, se))
1
```
"""
erosion(regions::Vector{Region}, se::Region) =
    _morph_map(r -> erosion(r, se), regions)

"""
    dilation(regions::Vector{Region}, se::Region)

Apply [`dilation`](@ref) to each region in `regions` with structuring element
`se`, returning a new vector that contains only the non-empty results.

```jldoctest
julia> using Regions

julia> regions = [region_from_box(-1, -1, 1, 1)];

julia> se = region_from_box(-1, -1, 1, 1);

julia> dilation(regions, se) == [region_from_box(-2, -2, 2, 2)]
true
```
"""
dilation(regions::Vector{Region}, se::Region) =
    _morph_map(r -> dilation(r, se), regions)

"""
    opening(regions::Vector{Region}, se::Region)

Apply [`opening`](@ref) to each region in `regions` with structuring element
`se`, returning a new vector that contains only the non-empty results.

```jldoctest
julia> using Regions

julia> large = region_from_box(-2, -2, 2, 2);

julia> pixel = Region([Run(0, 0:0)]);

julia> se    = region_from_box(-1, -1, 1, 1);

julia> length(opening([large, pixel], se))
1
```
"""
opening(regions::Vector{Region}, se::Region) =
    _morph_map(r -> opening(r, se), regions)

"""
    closing(regions::Vector{Region}, se::Region)

Apply [`closing`](@ref) to each region in `regions` with structuring element
`se`, returning a new vector that contains only the non-empty results.

```jldoctest
julia> using Regions

julia> gapped = Region([Run(-1, 0:0), Run(1, 0:0)]);

julia> se = region_from_box(-1, -1, 1, 1);

julia> c = closing([gapped], se);

julia> contains(c[1], 0, 0)
true
```
"""
closing(regions::Vector{Region}, se::Region) =
    _morph_map(r -> closing(r, se), regions)

"""
    morphological_gradient(regions::Vector{Region}, se::Region)

Apply [`morphological_gradient`](@ref) to each region in `regions` with
structuring element `se`, returning a new vector of non-empty results.

```jldoctest
julia> using Regions

julia> box = region_from_box(-2, -2, 2, 2);

julia> se  = region_from_box(-1, -1, 1, 1);

julia> grad = morphological_gradient([box], se);

julia> contains(grad[1], -2, 0) && !contains(grad[1], 0, 0)
true
```
"""
morphological_gradient(regions::Vector{Region}, se::Region) =
    _morph_map(r -> morphological_gradient(r, se), regions)

"""
    inner_boundary(regions::Vector{Region})

Apply [`inner_boundary`](@ref) to each region in `regions`, returning a new
vector of non-empty results.

```jldoctest
julia> using Regions

julia> box = region_from_box(-2, -2, 2, 2);

julia> ib = inner_boundary([box]);

julia> contains(ib[1], -2, 0) && !contains(ib[1], 0, 0)
true
```
"""
inner_boundary(regions::Vector{Region}) =
    _morph_map(inner_boundary, regions)

"""
    outer_boundary(regions::Vector{Region})

Apply [`outer_boundary`](@ref) to each region in `regions`, returning a new
vector of non-empty results.

```jldoctest
julia> using Regions

julia> box = region_from_box(-2, -2, 2, 2);

julia> ob = outer_boundary([box]);

julia> contains(ob[1], -3, 0) && !contains(ob[1], -2, 0)
true
```
"""
outer_boundary(regions::Vector{Region}) =
    _morph_map(outer_boundary, regions)

"""
    fill_holes(regions::Vector{Region})

Apply [`fill_holes`](@ref) to each region in `regions`, returning a new vector
with all holes filled.

```jldoctest
julia> using Regions

julia> frame = difference(region_from_box(-3, -3, 3, 3), region_from_box(-1, -1, 1, 1));

julia> filled = fill_holes([frame]);

julia> contains(filled[1], 0, 0)
true
```
"""
fill_holes(regions::Vector{Region}) =
    map(fill_holes, regions)

#= ------------------------------------------------------------------------

    Set-theoretic reductions and filtering on Vector{Region}

------------------------------------------------------------------------ =#

"""
    set_union(regions::Vector{Region}) -> Region

Return the set-theoretic union of every region in the vector. Equivalent to
`reduce(union, regions)`. An empty input vector yields an empty `Region`.

```jldoctest
julia> using Regions

julia> a = region_from_box(0, 0, 2, 2);

julia> b = region_from_box(5, 5, 7, 7);

julia> area(set_union([a, b])) == area(a) + area(b)
true

julia> isempty(set_union(Region[]))
true
```
"""
function set_union(regions::Vector{Region})
    isempty(regions) && return Region(Run[], false)
    return reduce(union, regions)
end

"""
    set_intersection(regions::Vector{Region}) -> Region

Return the set-theoretic intersection of every region in the vector. Equivalent
to `reduce(intersection, regions)`. The input must be non-empty.

```jldoctest
julia> using Regions

julia> a = region_from_box(0, 0, 5, 5);

julia> b = region_from_box(3, 3, 8, 8);

julia> c = region_from_box(4, 4, 9, 9);

julia> area(set_intersection([a, b, c]))
4
```
"""
function set_intersection(regions::Vector{Region})
    @assert !isempty(regions) "set_intersection requires a non-empty vector"
    return reduce(intersection, regions)
end

"""
    filter_area(regions::Vector{Region}, op, value::Real) -> Vector{Region}

Return the regions whose `area` satisfies `op(area(r), value)`. `op` is any
comparison function — typically one of `<`, `<=`, `==`, `!=`, `>=`, `>`.

```jldoctest
julia> using Regions

julia> small = Region([Run(0, 0:0)]);

julia> big   = region_from_box(0, 0, 5, 5);

julia> length(filter_area([small, big], >, 10))
1

julia> filter_area([small, big], >, 10)[1] == big
true
```
"""
filter_area(regions::Vector{Region}, op, value::Real) =
    filter(r -> op(area(r), value), regions)
