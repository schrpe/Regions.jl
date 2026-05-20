#= ------------------------------------------------------------------------

    Region Distance Transform

    City-block (4-connectivity, Manhattan) distance transform on a region.
    Returns a Matrix{Int} sized to the region's bounding box, where each
    region pixel holds its shortest 4-connected distance to the nearest
    background pixel and pixels outside the region hold 0.

    Algorithm: classic two-pass Rosenfeld–Pfaltz (Szeliski 2011, ch. 3.3.3).
    A forward pass propagates 1 + min(west, north) from the top-left, a
    backward pass propagates 1 + min(east, south) from the bottom-right and
    takes the minimum with the value from the first pass.

------------------------------------------------------------------------ =#

export distance_transform


"""
    distance_transform(r::Region) -> Matrix{Int}

Return the city-block (4-connected, Manhattan) distance transform of `r` as
a `Matrix{Int}` sized `(height(r), width(r))`. Index `[1, 1]` corresponds to
image pixel `(column = left(r), row = top(r))` — matching the indexing
convention used by [`region_to_image`](@ref).

For every pixel inside the region the matrix holds its shortest 4-connected
distance to the nearest pixel *outside* the region; boundary pixels are
therefore `1` and pixels outside the bounding box implicitly behave as `0`.
Locations inside the bounding box but outside the region (e.g. holes) are
`0`.

The implementation is the classic Rosenfeld–Pfaltz two-pass algorithm: a
forward pass sets each region pixel to `1 + min(west, north)` and a backward
pass takes the minimum with `1 + min(east, south)`. Neighbours outside the
region count as `0`, so the first interior pixel from any side always lands
at distance `1`.

Requires a non-empty, non-complement region.

```jldoctest
julia> using Regions

julia> distance_transform(Region([Run(0, 0:0)]))
1×1 Matrix{Int64}:
 1

julia> distance_transform(region_from_box(0, 0, 2, 2))
3×3 Matrix{Int64}:
 1  1  1
 1  2  1
 1  1  1
```
"""
function distance_transform(r::Region)
    @assert !r.complement "distance_transform is not defined for complement regions"
    @assert !isempty(r.runs) "distance_transform requires a non-empty region"

    l, t, ri, b = bounds(r)
    width  = ri - l + 1
    height = b - t + 1

    # Sentinel: large enough that `1 + sentinel` cannot overflow Int.
    SENTINEL = typemax(Int) ÷ 2

    dist = zeros(Int, height, width)
    @inbounds for run in r.runs
        col_idx = run.column - l + 1
        for row in run.rows
            dist[row - t + 1, col_idx] = SENTINEL
        end
    end

    # Forward pass: 1 + min(west, north).
    @inbounds for i in 1:height, j in 1:width
        if dist[i, j] != 0
            w = j > 1 ? dist[i, j - 1] : 0
            n = i > 1 ? dist[i - 1, j] : 0
            dist[i, j] = min(dist[i, j], 1 + min(w, n))
        end
    end

    # Backward pass: 1 + min(east, south).
    @inbounds for i in height:-1:1, j in width:-1:1
        if dist[i, j] != 0
            e = j < width  ? dist[i, j + 1] : 0
            s = i < height ? dist[i + 1, j] : 0
            dist[i, j] = min(dist[i, j], 1 + min(e, s))
        end
    end

    return dist
end
