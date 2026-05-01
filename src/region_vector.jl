#= ------------------------------------------------------------------------

    Vector{Region}

------------------------------------------------------------------------ =#

export left, top, right, bottom, bounds
export regions_to_image
export erosion, dilation, opening, closing
export morphological_gradient, inner_boundary, outer_boundary
export fill_holes

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

Calculates the maximum row coordinate across a vector of regions.
Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> top([Region([Run(2, 1:3)]), Region([Run(7, 2:6)])])
6

julia> ismissing(top(Region[]))
true
```
"""
function top(regions::Vector{Region})
    if !isempty(regions)
        t = top(regions[1])
        for region in regions
            t = max(t, top(region))
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

Calculates the minimum row coordinate across a vector of regions.
Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> bottom([Region([Run(2, 1:3)]), Region([Run(7, 5:8)])])
1

julia> ismissing(bottom(Region[]))
true
```
"""
function bottom(regions::Vector{Region})
    if !isempty(regions)
        b = bottom(regions[1])
        for region in regions
            b = min(b, bottom(region))
        end
        return b
    else
        return missing
    end
end

"""
    bounds(x::Vector{Region})

Calculates `(left, top, right, bottom)` — the minimum column, maximum row, maximum column,
and minimum row — across all regions in the vector. Returns `missing` for an empty vector.

```jldoctest
julia> using Regions

julia> bounds([Region([Run(2, 1:3)]), Region([Run(7, 2:6)])])
(2, 6, 7, 1)

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
            t = max(t, top(region))
            r = max(r, right(region))
            b = min(b, bottom(region))
        end
        return l, t, r, b
    else
        return missing
    end
end

"""
    regions_to_image(regions::Vector{Region}, colors=[Gray(true)])

Converts a vector of regions to an image. The function determines the bounds of the
regions and then renders the regions into the image.

The background of the image is filled with zeroes, the region pixels are
colored with the passed in colors. Colors are cycled when there are more regions than colors.

Some examples of colors that you can pass:
[Gray(0.5)] : mid gray value applied to all regions
[RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1)] : cycle through red, green and blue
[RGBA(0, 0.5, 0, 0.5), RGBA(0.5, 0, 0, 0.5)] : half transparent mid green and mid red values
"""
function regions_to_image(regions::Vector{Region}, colors=[Gray(true)])
    (l, t, r, b) = bounds(regions)
    img = zeros(eltype(colors), t-b+1, r-l+1)
    n = 1
    for region in regions 
        for run in region.runs
            for row in run.rows
                ca = color(colors[n])
                aa = alpha(colors[n])
                cb = color(img[row-b+1, run.column-l+1])
                ab = alpha(img[row-b+1, run.column-l+1])
                ac = aa + (1 - aa) * ab
                cc = (aa * ca + (1 - aa) * ab * cb) / ac
                img[row-b+1, run.column-l+1] = eltype(colors)(cc, ac)
            end
        end
        n = mod1(n + 1, length(colors))
    end
    return img
end

"""
    Base.show(io, mime::MIME"image/png", regions::Region[])

Shows a rich graphical display of a vector of regions. The colors cycle through
half transparent blue, green, red, cyan, magenta and yellow colors.
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

julia> regions = [region_from_box(-2, 2, 2, -2), Region([Run(0, 0:0)])];

julia> se = region_from_box(-1, 1, 1, -1);

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

julia> regions = [region_from_box(-1, 1, 1, -1)];

julia> se = region_from_box(-1, 1, 1, -1);

julia> dilation(regions, se) == [region_from_box(-2, 2, 2, -2)]
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

julia> large = region_from_box(-2, 2, 2, -2);

julia> pixel = Region([Run(0, 0:0)]);

julia> se    = region_from_box(-1, 1, 1, -1);

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

julia> se = region_from_box(-1, 1, 1, -1);

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

julia> box = region_from_box(-2, 2, 2, -2);

julia> se  = region_from_box(-1, 1, 1, -1);

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

julia> box = region_from_box(-2, 2, 2, -2);

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

julia> box = region_from_box(-2, 2, 2, -2);

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

julia> frame = difference(region_from_box(-3, 3, 3, -3), region_from_box(-1, 1, 1, -1));

julia> filled = fill_holes([frame]);

julia> contains(filled[1], 0, 0)
true
```
"""
fill_holes(regions::Vector{Region}) =
    map(fill_holes, regions)
