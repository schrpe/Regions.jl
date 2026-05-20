#= ------------------------------------------------------------------------

    Region-bounded Profiles

    Sum pixel values of an image over the pixels of a Region, projected
    onto one axis. Indexing convention follows the package convention:
    image[row, column], (column, row) = (x, y).

------------------------------------------------------------------------ =#

export profile_horizontal, profile_vertical


# Promote integer pixel types (UInt8, Int16, ...) to a safe accumulator type
# to avoid silent overflow. Floating-point and color types are kept as-is so
# Gray{Float64}/RGB images sum natively.
@inline _profile_acc_type(::Type{T}) where {T<:Integer} = Int64
@inline _profile_acc_type(::Type{T}) where {T} = T


"""
    profile_horizontal(r::Region, image::AbstractMatrix) -> Vector

Return the row-wise sum of `image` pixels that fall inside the non-empty,
non-complement region `r`. The returned vector has length `height(r)`; index
`i` corresponds to image row `top(r) + i - 1`.

Pixels outside the region are not counted, so this is equivalent to masking
the image with the region and then summing along the column axis.

`image` is indexed as `image[row, column]` (the package's standard
convention) and must contain every pixel of `r`'s bounding box.

```jldoctest
julia> using Regions

julia> img = Float64[1 2 3; 4 5 6; 7 8 9];

julia> r = region_from_box(1, 1, 3, 3);

julia> profile_horizontal(r, img)
3-element Vector{Float64}:
  6.0
 15.0
 24.0
```
"""
function profile_horizontal(r::Region, image::AbstractMatrix)
    @assert !r.complement && !isempty(r.runs) "profile_horizontal requires a non-empty, non-complement region"
    rows_img, cols_img = size(image)
    l, t, ri, b = bounds(r)
    @assert 1 <= l && ri <= cols_img && 1 <= t && b <= rows_img "region exceeds image bounds"

    T = _profile_acc_type(eltype(image))
    result = zeros(T, b - t + 1)
    @inbounds for run in r.runs
        c = run.column
        for row in run.rows
            result[row - t + 1] += image[row, c]
        end
    end
    return result
end


"""
    profile_vertical(r::Region, image::AbstractMatrix) -> Vector

Return the column-wise sum of `image` pixels that fall inside the non-empty,
non-complement region `r`. The returned vector has length `width(r)`; index
`i` corresponds to image column `left(r) + i - 1`.

Pixels outside the region are not counted, so this is equivalent to masking
the image with the region and then summing along the row axis.

`image` is indexed as `image[row, column]` (the package's standard
convention) and must contain every pixel of `r`'s bounding box.

```jldoctest
julia> using Regions

julia> img = Float64[1 2 3; 4 5 6; 7 8 9];

julia> r = region_from_box(1, 1, 3, 3);

julia> profile_vertical(r, img)
3-element Vector{Float64}:
 12.0
 15.0
 18.0
```
"""
function profile_vertical(r::Region, image::AbstractMatrix)
    @assert !r.complement && !isempty(r.runs) "profile_vertical requires a non-empty, non-complement region"
    rows_img, cols_img = size(image)
    l, t, ri, b = bounds(r)
    @assert 1 <= l && ri <= cols_img && 1 <= t && b <= rows_img "region exceeds image bounds"

    T = _profile_acc_type(eltype(image))
    result = zeros(T, ri - l + 1)
    @inbounds for run in r.runs
        c = run.column
        s = zero(T)
        for row in run.rows
            s += image[row, c]
        end
        result[c - l + 1] += s
    end
    return result
end
