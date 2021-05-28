#= ------------------------------------------------------------------------

    Region

------------------------------------------------------------------------ =#

import Base: copy, -, union, ==, show
export Region
export isempty, ==, copy, invert, -, translate, translate!, contains, ∈
export left, top, right, bottom, bounds
export complement, complement!
export union, intersection, difference
export region_from_box
export region_to_image

"""
    Region

A region is a discrete set of coordinates in two-dimensional euclidean space.

A region consists of zero or more runs, which are sorted in ascending order.
"""
struct Region
    runs::Vector{Run}
    complement::Bool
end

Region(runs::Vector{Run}) = Region(runs, false)

"""
    isempty(x::Region)

Discover whether the region is empty.

```jldoctest
julia> using Regions

julia> isempty(Region(Run[]))
true

julia> isempty(Region([Run(2, 1:1)]))
false
```
"""
isempty(x::Region) = isempty(x.runs)

"""
    ==(a::Region, b::Region)

Equality operator for two regions. Two regions are equal, if both their runs and their 
complement flags are equal.
"""
==(a::Region, b::Region) = a.runs == b.runs && a.complement == b.complement

"""
    copy(x::Region)
    
Create a copy of a region.    
"""
copy(x::Region) = Region(copy(x.runs), x.complement)

"""
    invert(x::Region)
    -(x::Region)

Invert a region. Inversion mirrors a region at the origin. A region is inverted
by inverting each of its runs. Since the runs of a region are sorted by their row and
column coordinates, the order of the runs is inversed as well.
"""
function invert(x::Region)
    result = Region(Run[], x.complement) # TODO how to reserve space?
    # iterating backwards maintains the correct sort order of the runs
    for i in length(x.runs):-1:1
        push!(result.runs, -x.runs[i])
    end
    return result
end

-(x::Region) = invert(x)

"""
    translate(r::Region, x::Integer, y::Integer)
    translate(r::Region, a::Vector{Int64})

Translate a region. Translation moves a region. A region is translated by translating each 
of its runs. 
"""
function translate(r::Region, x::Integer, y::Integer)
    return translate!(copy(r), x, y)
end
translate(r::Region, d::Vector{Int64}) = translate(r, d[1], d[2])
+(x::Region, y::Vector{Int64}) = translate(x, y[1], y[2])
+(x::Vector{Int64}, y::Region) = translate(y, x[1], x[2])
-(x::Region, y::Vector{Int64}) = translate(x, -y[1], -y[2])
function translate!(r::Region, x::Integer, y::Integer)
    for i in [1, length(r.runs)]
        r.runs[i] = translate(r.runs[i], x, y)
    end
    return r
end
translate!(r::Region, d::Vector{Int64}) = translate!(r, d[1], d[2])

"""
    contains(r::Region, x::Integer, y::Integer)
    contains(r::Region, a::Array{Int64, 1})

Test if region r contains position (x, y).
"""
contains(r::Region, x::Integer, y::Integer) = r.complement ? !any(run -> contains(run, x, y), r.runs) : any(run -> contains(run, x, y), r.runs)
contains(r::Region, a::Array{Int64, 1}) = contains(r, a[1], a[2])
∈(r::Region, a::Array{Int64, 1}) = contains(r, a)

"""
    left(x::Region)

Calculates the leftmost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function left(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert length(r.runs)>0 "cannot calculate for empty regions"
    v = r.runs[1].columns.start
    for i in r.runs
        v = min(v, i.columns.start)
    end
    return v
end

"""
    top(x::Region)

Calculates the topmost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function top(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert length(r.runs)>0 "cannot calculate for empty regions"
    v = r.runs[1].row
    for i in r.runs
        v = max(v, i.row)
    end
    return v
end

"""
    right(x::Region)

Calculates the rightmost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function right(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert length(r.runs)>0 "cannot calculate for empty regions"
    v = r.runs[1].columns.stop
    for i in r.runs
        v = max(v, i.columns.stop)
    end
    return v
end

"""
    bottom(x::Region)

Calculates the bottommost region coordinate.

This function works for non-complement and non-empty regions only.
"""
function bottom(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert length(r.runs)>0 "cannot calculate for empty regions"
    v = r.runs[1].row
    for i in r.runs
        v = min(v, i.row)
    end
    return v
end

"""
    bounds(x::Region)

Calculates the left, top, right and bottom region coordinate and returns them
as a tuple.

This function works for non-complement and non-empty regions only.
"""
function bounds(region::Region)
    @assert !region.complement "cannot calculate for infinite (complement) regions"
    @assert length(region.runs)>0 "cannot calculate for empty regions"
    l = region.runs[1].columns.start
    t = region.runs[1].row
    r = region.runs[1].columns.stop
    b = region.runs[1].row
    for run in region.runs
        l = min(l, run.columns.start)
        t = max(t, run.row)
        r = max(r, run.columns.stop)
        b = min(b, run.row)
    end
    return l, t, r, b
end

"""
    complement(x::Region)

Calculates the set-theoretic complement of a region.

With a non-complemented region, the runs specify the contained pixels, i.e. they specify
what is included within the region. With a complemented region, the runs specify the
non-contained pixels, i.e. they specify what is not included within the region.
"""
complement(x::Region) = Region(copy(x.runs), !x.complement)
complement!(x::Region) = x.complement =! x.complement

"""
    merge(a::Vector{Run}, b::Vector{Run})

Merge sorted vectors `a` and `b`. Assumes that `a` and `b` are sorted 
and does not check whether `a` or `b` are sorted. 

merge is not exported, since its basic usage is within this file and it conflicts with
a definition in Base.
"""
function merge(a::Vector{Run}, b::Vector{Run})
    res = Run[]
    i = 1
    j = 1
    while i <= length(a)
        if j > length(b)
            while i <= length(a)
                push!(res, a[i])
                i = i+1
            end
            return res
        end
        if (b[j] < a[i])
            push!(res, b[j])
            j = j+1
        else
            push!(res, a[i])
            i = i+1
        end
    end
    while j <= length(b)
        push!(res, b[j])
        j = j+1
    end
    return res
end

"""
    sort(a::Vector{Run})

Variant of sort that returns a sorted copy of a leaving a itself unmodified. This ensures that
runs are sorted after an operation that might have destroyed the sort order, such as 
downsampling.
"""
sort(a::Vector{Run}) = sort(a)

"""
    sort!(a::Vector{Run})

Sort the vector a in place. This ensures that runs are sorted after an operation that might 
have destroyed the sort order, such as downsampling.
"""
sort!(a::Vector{Run}) = sort!(a)

"""
    pack!(a::Vector{Run})

Packs runs together. pack! is not exported, since its basic usage is within this file as a 
building block for union.
"""
function pack!(a::Vector{Run})
    read = 1
    write = 1

    while read <= length(a)
        a[write] = a[read]
        read += 1

        while read <= length(a) && a[write].row == a[read].row && a[write].columns.stop + 1 >= a[read].columns.start
            if a[read].columns.stop > a[write].columns.stop
                a[write] = Run(a[read].row, a[write].columns.start:a[read].columns.stop)
            end
            read += 1
        end
        write += 1
    end
    deleteat!(a, write:length(a))
end

"""
    union(a::Vector{Run}, b::Vector{Run})

Calculates the union of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function union(a::Vector{Run}, b::Vector{Run})
    res = merge(a, b)
    pack!(res)
    return res
end

"""
    union(a::Region, b::Region)

Calculates the union of two regions. This function supports complement regions and uses 
DeMorgan's rules to eliminate the complement.    
"""
function union(a::Region, b::Region)
    if a.complement && b.complement
        return Region(intersection(a.runs, b.runs), true)
    elseif a.complement
        return Region(difference(a.runs, b.runs), true)
    elseif b.complement
        return Region(difference(b.runs, a.runs), true)
    else
        return Region(union(a.runs, b.runs), false)
    end
end


"""
    intersect!(a::Vector{Run})

Intersects runs. intersect! is not exported, since its basic usage is within this file as a 
building block for intersection.
"""
function intersect!(a::Vector{Run})
    read = 1
    if read > length(a)
        return
    end
    next = read + 1
    write = read
    while next <= length(a)
        if a[read].row != a[next].row
            read = next
            next += 1
        else
            if a[next].columns.start > a[read].columns.stop
                read = next
                next += 1
            else
                a[write] = Run(a[read].row, a[next].columns.start:min(a[read].columns.stop, a[next].columns.stop))
                if a[next].columns.stop < a[read].columns.stop
                    a[next] = a[read]
                end
                read = next
                next += 1
                write += 1
            end
        end
    end
    deleteat!(a, write:length(a))
end

"""
    intersection(a::Vector{Run}, b::Vector{Run})

Calculates the intersection of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function intersection(a::Vector{Run}, b::Vector{Run})
    res = merge(a, b)
    intersect!(res)
    return res
end

"""
    intersection(a::Region, b::Region)

Calculates the intersection of two regions. This function supports complement regions and uses 
DeMorgan's rules to eliminate the complement.    
"""
function intersection(a::Region, b::Region)
    if a.complement && b.complement
        return Region(union(a.runs, b.runs), true)
    elseif a.complement
        return Region(difference(b.runs, a.runs), false)
    elseif b.complement
        return Region(difference(a.runs, b.runs), false)
    else
        return Region(intersection(a.runs, b.runs), false)
    end
end

"""
    difference(a::Vector{Run}, b::Vector{Run})

Calculates the difference of two sorted vectors of runs. The function assumes that the runs are sorted
but does not check this.
"""
function difference(a::Vector{Run}, b::Vector{Run})
    if length(a) == 0
        return Run[]
    end

    if length(b) == 0
        return a
    end

    res = Run[]

    # first_b and last_b form a range of chords in b that are in the same row
    first_b = findfirst(x -> x.row >= a[1].row, b)
    last_b = first_b
    if first_b != nothing
        last_b = findlast(x -> x.row == b[first_b].row, view(b, first_b:length(b)))
    end

    for a_index in 1:length(a)
        if first_b != nothing && a[a_index].row > b[first_b].row
            # update the range
            first_b = findfirst(x -> x.row >= a[a_index].row, b)
            last_b = first_b
            if first_b != nothing
                last_b = findlast(x -> x.row == b[first_b].row, view(b, first_b:length(b)))
            end
        end
        if first_b == nothing || a[a_index].row != b[first_b].row
            push!(res, a[a_index])
        else
            for i in first_b:last_b
                if isoverlapping(a[a_index], b[i])
                    # total overlap, erase all of a_chord and break
                    if b[i].columns.start <= a[a_index].columns.start && b[i].columns.stop >= a[a_index].columns.stop
                        a[a_index] = Run(a[a_index].row, a[a_index].columns.start:a[a_index].columns.start-1)
                        break;
                    # overlap at left only, shorten a_chord at left and continue
                    elseif b[i].columns.start <= a[a_index].columns.start
                        a[a_index] = Run(a[a_index].row, b[i].columns.stop+1:a[a_index].columns.stop)
                    # overlap at right only, shorten a_chord at right and continue
                    elseif b[i].columns.stop >= a[a_index].columns.stop
                        a[a_index] = Run(a[a_index].row, a[a_index].columns.start:b[i].columns.start-1)
                    # overlap in the middle, split a_chord into two and continue
                    else
                        push!(res, Run(a[a_index].row, a[a_index].columns.start:b[i].columns.start-1))
                        a[a_index] = Run(a[a_index].row, b[i].columns.stop+1:a[a_index].columns.stop)
                    end
                end
            end
            if !isempty(a[a_index])
                push!(res, a[a_index])
            end
        end
    end

    return res
end

"""
    difference(a::Region, b::Region)

Calculates the union of two regions. This function supports complement regions and uses 
DeMorgan's rules to eliminate the complement.
"""
function difference(a::Region, b::Region)
    if a.complement && b.complement
        return Region(difference(b.runs, a.runs), false)
    elseif a.complement
        return Region(union(a.runs, b.runs), true)
    elseif b.complement
        return Region(intersection(a.runs, b.runs), false)
    else
        return Region(difference(a.runs, b.runs), false)
    end
end

"""
    region_from_box(left::Integer, top::Integer, right::Integer, bottom::Integer)

Create a region given box coordinates. The region consists of all coordinates within the box.
"""
function region_from_box(left::Integer, top::Integer, right::Integer, bottom::Integer)
    @assert bottom < top "bottom must be smaller than top"
    @assert left < right "left must be smaller than right"

    region = Region(Run[])
    for row in bottom:top
        push!(region.runs, Run(row, left:right))
    end
    return region
end

"""
    region_to_image(r::Region, color=Gray(true))

Converts a region to an image. The function determines the bounds of the
region and then renders the region into the image.

The background of the image is filled with zeroes, the region pixels are
colored with the passed in color.

Some examples of colors that you can pass:
Gray(0.5) : mid gray value
RGB(1, 0, 0) : brightest red value
RGBA(0, 0.5, 0, 0.5) : half transparent mid green value
"""
function region_to_image(region::Region, color=Gray(true))
    (l, t, r, b) = bounds(region)
    img = zeros(typeof(color), t-b+1, r-l+1)
    for run in region.runs
        for column in run.columns
            img[run.row-b+1, column-l+1] = color
        end
    end
    return img
end

"""
    Base.show(io, mime::MIME"image/png", r::Region)

Shows a rich graphical display of a region. The region is displayed in a half 
transparent blue color.
"""
function Base.show(io::IO, mime::MIME"image/png", region::Region)
    if !isempty(region)
        Base.show(io, mime, region_to_image(region, RGBA(0,0,1,0.5)))
    end
end

