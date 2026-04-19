#= ------------------------------------------------------------------------

    Vector{Region}

------------------------------------------------------------------------ =#

export left, top, right, bottom, bounds
export regions_to_image

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
