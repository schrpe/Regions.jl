#= ------------------------------------------------------------------------

    Vector{Region}

------------------------------------------------------------------------ =#

export left, top, right, bottom, bounds
export regions_to_image

"""
    left(x::Vector{Region})

Calculates the leftmost coordinate of a vector of regions.

This function works for non-complement and non-empty regions only. The vector
must not be empty.
"""
function left(regions::Vector{Region})
    if length(regions) > 0
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

Calculates the topmost region coordinate of a vector of regions.

This function works for non-complement and non-empty regions only. The vector
must not be empty.
"""
function top(regions::Vector{Region})
    if length(regions) > 0
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

Calculates the rightmost region coordinate of a vector of regions.

This function works for non-complement and non-empty regions only. The vector
must not be empty.
"""
function right(regions::Vector{Region})
    if length(regions) > 0
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

Calculates the bottommost region coordinate of a vector of regions.

This function works for non-complement and non-empty regions only. The vector
must not be empty.
"""
function bottom(regions::Vector{Region})
    if length(regions) > 0
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

Calculates the left, top, right and bottom region coordinate of a vector of regions
and returns them as a tuple.

This function works for non-complement and non-empty regions only. The vector
must not be empty.
"""
function bounds(regions::Vector{Region})
    if length(regions) > 0
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
    regions_to_image(r::Region, color=Gray(true))

Converts a vector of regions to an image. The function determines the bounds of the
regions and then renders the regions into the image.

The background of the image is filled with zeroes, the region pixels are
colored with the passed in colors.

Some examples of colors that you can pass:
[Gray(0.5)] : mid gray value
[RGB(1, 0, 0), RGB(1, 0, 0), RGB(1, 0, 0)] : cycle through red, green and blue
[RGBA(0, 0.5, 0, 0.5), RGBA(0.5, 0, 0, 0.5)] : half transparent mid green and mid red values
"""
function regions_to_image(regions::Vector{Region}, colors=[Gray(true)])
    (l, t, r, b) = bounds(regions)
    img = zeros(typeof(colors[1]), t-b+1, r-l+1)
    color = 1
    for region in regions 
        for run in region.runs
            for column in run.columns
                img[run.row-b+1, column-l+1] = colors[color]
            end
        end
        color += 1
        if (color > length(colors))
            color = 1
        end
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
