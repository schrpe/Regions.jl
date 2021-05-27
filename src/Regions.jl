"""
    Regions

Main module for Regions.jl - a set of types that model a discrete 2-dimensional region concept.

# Exports

* Run   
* Region

# Dependencies

* Images.jl

"""
module Regions

using Images

export binarize, components

include("range.jl")
include("run.jl")
include("region.jl")
include("region_vector.jl")

"""
    binarize(image, predicate)

Binarize an image and return a region.

The predicate must be a funtion that takes a pixel value and returns a boolean result based
on the pixel value.

Here are some useful examples:

# the returned region will contain all pixels > 0.3
reg = binarize(img, x -> x > 0.3)

# the returned region will contain all pixels <= 0.5
reg = binarize(img, x -> x <= 0.5)

# the returned region will contain all pixels between 0.3 and 0.8
reg = binarize(img, x -> x > 0.3 && x < 0.8)

"""
function binarize(image, predicate)
    region = Region(Run[], false) 

    rows, columns = size(image)

    for row in 1:rows
        inside_object = false
        start_column = 0
        for column in 1:columns
            if predicate(image[row, column]) 
                if false == inside_object
                    inside_object = true
                    start_column = column
                end
            else
                if true == inside_object
                    inside_object = false
                    push!(region.runs, Run(row, start_column:(column-1)))
                end
            end
        end
        # if still inside at the end of a line...
        if true == inside_object
            push!(region.runs, Run(row, start_column:columns))
        end
    end

    return region
end

"""
    components(region::Region, dx::Unsigned=1, dy::Unsigned=1)

This function splits a region into connected component objects that are returned as a vector of regions.

The dx and dy parameters specify the size of gaps that are still considered to be the same object.
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

    ## see ngi::chord::are_chords_close; this is required for 4-connectivity
    dy = max(1, dy)
    for run in region.runs
        next_run_index = run_index + 1
        while next_run_index <= length(region.runs) &&
            region.runs[next_run_index].row <= run.row + dy
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

    for idx = 1:length(union_find)
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

end # module
