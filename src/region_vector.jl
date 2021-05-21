#= ------------------------------------------------------------------------

    Vector{Region}

------------------------------------------------------------------------ =#

"""
    left(x::Vector{Region})

Calculates the leftmost region coordinate.

This function works for non-complement and non-empty regions only.
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

Calculates the topmost region coordinate.

This function works for non-complement and non-empty regions only.
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

Calculates the rightmost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function right(regions::Vector{Region})
    if length(regions) > 0
        r = right(regions[1])
        for region in regions
            top = max(r, right(region))
        end
        return r
    else
        return missing
    end
end

"""
    bottom(x::Vector{Region})

Calculates the bottommost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function bottom(regions::Vector{Region})
    if length(regions) > 0
        b = bottom(regions[1])
        for region in regions
            top = min(b, bottom(region))
        end
        return b
    else
        return missing
    end
end

function width(regions::Vector{Region})
    if length(regions) > 0
        return right(regions)-left(regions)+1
    else
        return missing
    end
end

function height(regions::Vector{Region})
    if length(regions) > 0
        return top(regions)-bottom(regions)+1
    else
        return missing
    end
end
