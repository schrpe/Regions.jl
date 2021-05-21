"""
    Regions

Main module for Regions.jl - a set of types that model a discrete 
2-dimensional region concept.

# Exports

* Run   
* Region

# Dependencies

* Images.jl

"""
module Regions

include("range.jl")
include("run.jl")
include("region.jl")
include("region_vector.jl")


#=
The following functions should go into blob or thresholding module
=#

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
    connection(region::Region, dx::Integer, dy::Integer)

This function splits a region into connected objects that are returned as a vector of regions.
"""
function connection(region::Region, dx::Integer, dy::Integer)
    @assert dx >= 0 "dx must be 0 or bigger"
    @assert dy >= 0 "dy must be 0 or bigger"

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


using Images


"""
    Base.show(io, mime::MIME"image/png", r::Region)

Shows a rich graphical display of a region. 
"""
function Base.show(io::IO, mime::MIME"image/png", region::Region)
    # convert region to an image and show image
    x0 = left(region)
    y0 = bottom(region)
    img = zeros(RGBA{N0f8}, height(region), width(region))
    for run in region.runs
        for column in run.columns
            img[run.row-y0+1, column-x0+1] = RGBA(0,0,1,0.5)
        end
    end
    Base.show(io, mime, img)
end


"""
    Base.show(io, mime::MIME"image/png", regions::Region[])

Shows a rich graphical display of a vector of regions. 
"""
function Base.show(io::IO, mime::MIME"image/png", regions::Vector{Region})
    # convert region vector to an image and show image
    x0 = left(regions)
    y0 = bottom(regions)
    img = zeros(RGBA{N0f8}, height(regions)+100, width(regions)+100)
    red = RGBA(1,0,0,0.5)
    green = RGBA(0,1,0,0.5)
    blue = RGBA(0,0,1,0.5)
    color = red
    for region in regions 
        for run in region.runs
            for column in run.columns
                img[run.row-y0+1, column-x0+1] =color
            end
        end
        if red == color
            color = green
        elseif green == color
            color = blue
        else
            color = red
        end
    end
    Base.show(io, mime, img)
end


end # module
