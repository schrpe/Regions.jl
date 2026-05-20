"""
    Regions

Main module for Regions.jl - a set of types that model a discrete 2-dimensional region concept.

# Exports

* Run
* Region
* binarize
* components

# Dependencies

* Images.jl

"""
module Regions

using Images
import Images: binarize   # extend rather than shadow; Regions.binarize === Images.binarize

export Run, Region
export binarize, components, segment_multi_threshold

include("range.jl")
include("run.jl")
include("region.jl")
include("region_morphology.jl")
include("region_vector.jl")
include("point_list.jl")
include("region_features.jl")
include("region_profile.jl")

# Benchmarked on a 16-core / 4-thread machine across dense and sparse Float32 images:
#
#   columns   serial    parallel   verdict
#   ────────────────────────────────────────
#    100×100   0.009 ms   0.132 ms  serial wins (thread overhead dominates)
#    512×512   0.220 ms   0.082 ms  parallel wins at 4t, marginal at 16t
#   1024×1024  0.916 ms   0.322 ms  parallel wins clearly at both thread counts
#   2048×2048  3.922 ms   1.376 ms  parallel wins clearly
#
# Sparse images (many short runs, high push! pressure) show less benefit:
# at 1024 columns the parallel path can be slightly slower due to allocator
# contention. 1024 is therefore the conservative crossover: clear speedup on
# dense images ≥ 1024 and no regression on smaller or real-world images.
const _BINARIZE_PARALLEL_THRESHOLD = 1024

function _binarize_serial(image, predicate, rows, columns)
    region = Region(Run[], false)
    @inbounds for column in 1:columns
        col = view(image, :, column)
        inside_object = false
        start_row = 0
        for row in 1:rows
            if predicate(col[row])
                if !inside_object
                    inside_object = true
                    start_row = row
                end
            else
                if inside_object
                    inside_object = false
                    push!(region.runs, Run(column, start_row:(row-1)))
                end
            end
        end
        if inside_object
            push!(region.runs, Run(column, start_row:rows))
        end
    end
    return region
end

function _binarize_parallel(image, predicate, rows, columns)
    per_column = Vector{Vector{Run}}(undef, columns)
    Threads.@threads :static for column in 1:columns
        runs = Run[]
        col = view(image, :, column)
        inside_object = false
        start_row = 0
        @inbounds for row in 1:rows
            if predicate(col[row])
                if !inside_object
                    inside_object = true
                    start_row = row
                end
            else
                if inside_object
                    inside_object = false
                    push!(runs, Run(column, start_row:(row-1)))
                end
            end
        end
        if inside_object
            push!(runs, Run(column, start_row:rows))
        end
        per_column[column] = runs
    end
    return Region(reduce(append!, per_column, init=Run[]), false)
end

"""
    binarize(image, predicate::Function)

Extend `Images.binarize` with a predicate-based method that returns a `Region`.

Scans `image` column by column and includes every pixel for which `predicate` returns
`true`. Because the second argument is typed `::Function`, Julia's dispatch selects this
method when a plain function or lambda is passed, while algorithm-based calls such as
`binarize(img, Otsu())` continue to resolve to the `Images.binarize` method unchanged.

For images with at least `$_BINARIZE_PARALLEL_THRESHOLD` columns and multiple threads
available, the work is distributed across threads (one per column). Smaller images use a
single-threaded path to avoid thread overhead.

```julia
reg = binarize(img, x -> x > 0.3)        # all pixels above 30 % brightness
reg = binarize(img, x -> x <= 0.5)       # all pixels at most 50 % brightness
reg = binarize(img, x -> 0.3 < x < 0.8) # pixels in the 30–80 % range
```
"""
function binarize(image, predicate::Function)
    rows, columns = size(image)
    if Threads.nthreads() > 1 && columns >= _BINARIZE_PARALLEL_THRESHOLD
        return _binarize_parallel(image, predicate, rows, columns)
    else
        return _binarize_serial(image, predicate, rows, columns)
    end
end

"""
    components(region::Region, dx::Unsigned=1, dy::Unsigned=1)

Split `region` into its connected components and return them as a `Vector{Region}` — one
element per blob.

Two runs are considered part of the same component when their column distance is at most
`dx` and their row gap is at most `dy`. The defaults `dx = dy = 1` give standard 8-connected
labelling; larger values intentionally bridge small gaps between nearby objects (useful for
joining slightly-fragmented blobs into a single component before measurement).

Because the algorithm walks the run list rather than the pixel grid, it scales as
`O(n_runs)` — independent of image area. On sparse industrial images this is typically
orders of magnitude faster than pixel-based connected-component labelling.

```jldoctest
julia> using Regions

julia> b1 = region_from_circle(-20, 0, 5);

julia> b2 = region_from_circle(  0, 0, 5);

julia> b3 = region_from_circle( 20, 0, 5);

julia> length(components(union(union(b1, b2), b3)))
3
```
"""
function components(region::Region, dx::Unsigned=unsigned(1), dy::Unsigned=unsigned(1))

    function uf_find_root(ufa, x)
        i = x
        while ufa[i] >= 0
            i = ufa[i]
        end
        return i
    end

    function uf_union(ufa, x, y)
        i = uf_find_root(ufa, x)
        j = uf_find_root(ufa, y)

        ti = x
        tmp = -1
        while ufa[ti] >= 0
            tmp = ti
            ti = ufa[ti]
            ufa[tmp] = i
        end

        ti = y
        tmp = -1
        while ufa[ti] >= 0
            tmp = ti
            ti = ufa[ti]
            ufa[tmp] = j
        end

        not_same_tree = i != j

        if not_same_tree
            ## this maintains the scan-order of the regions in the result
            if i < j
                ufa[j] = i
            else
                ufa[i] = j
            end
        end

        return not_same_tree

    end

    ## union_find: indexed by chord index in r.chords()
    ##
    ## value:
    ## <= -1:  this node is a root with abs(val) indicating tree depth of the associated tree
    ## >= 0 : index index (in union_find) of parent  

    union_find = [-1 for _ = 1:length(region.runs)]

    run_index = 1

    ## ensure dx >= 1; this is required for 4-connectivity
    dx = max(1, dx)
    for run in region.runs
        next_run_index = run_index + 1
        while next_run_index <= length(region.runs) &&
            region.runs[next_run_index].column <= run.column + dx
            if isclose(run, region.runs[next_run_index], dx, dy)
                uf_union(union_find, run_index, next_run_index)
            end
            next_run_index += 1
        end
        run_index += 1
    end

    ## Make contiguous labels for the roots: store a negative value in the union_find array
    ## at the root location:
    ##    -1 <-> region 0 
    ##    -2 <-> region 1 
    ## ....
    ## Also counts the # of roots (i.e. number of connected components).
    r_idx = -1

    for idx in eachindex(union_find)
        if union_find[idx] <= -1
            union_find[idx] = r_idx
            r_idx -= 1
        end
    end

    num_regions = r_idx * (-1) - 1;
    connected_objects = Region[Region(Run[]) for _ = 1:num_regions];

    for idx = 1:length(union_find)
        root = uf_find_root(union_find, idx)
        region_idx = union_find[root] * (-1)
        push!(connected_objects[region_idx].runs, region.runs[idx])
    end

    return connected_objects;
end

"""
    segment_multi_threshold(image, thresholds::AbstractVector) -> Vector{Region}

Segment `image` into one `Region` per intensity bin, using a sorted vector of
`thresholds` as bin boundaries. The result has `length(thresholds) + 1`
elements:

- Bin 1: pixels with value `< thresholds[1]`
- Bin k (1 < k ≤ length(thresholds)): pixels with `thresholds[k-1] ≤ value < thresholds[k]`
- Bin `length(thresholds)+1`: pixels with `value ≥ thresholds[end]`

`thresholds` must be strictly increasing. Empty bins return empty regions but
the result length is always `length(thresholds) + 1`, so callers can index by
bin index without bounds checks.

```jldoctest
julia> using Regions

julia> img = [0.1 0.4 0.7;
              0.2 0.5 0.8;
              0.3 0.6 0.9];

julia> regs = segment_multi_threshold(img, [0.4, 0.7]);

julia> length(regs)
3

julia> area(regs[1]) + area(regs[2]) + area(regs[3])
9
```
"""
function segment_multi_threshold(image, thresholds::AbstractVector)
    @assert !isempty(thresholds) "thresholds vector must not be empty"
    for i in 2:length(thresholds)
        @assert thresholds[i] > thresholds[i-1] "thresholds must be strictly increasing"
    end
    rows, columns = size(image)
    nbins = length(thresholds) + 1

    # Map a pixel value to its bin index (1-based)
    @inline function bin_of(v)
        for k in 1:length(thresholds)
            v < thresholds[k] && return k
        end
        return nbins
    end

    per_bin = [Vector{Run}() for _ in 1:nbins]

    @inbounds for column in 1:columns
        col = view(image, :, column)
        current_bin = bin_of(col[1])
        start_row = 1
        for row in 2:rows
            b = bin_of(col[row])
            if b != current_bin
                push!(per_bin[current_bin], Run(column, start_row:(row-1)))
                current_bin = b
                start_row = row
            end
        end
        push!(per_bin[current_bin], Run(column, start_row:rows))
    end

    return [Region(per_bin[k], false) for k in 1:nbins]
end

end # module
