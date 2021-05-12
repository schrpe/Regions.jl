"""
    Regions

Main module for Regions.jl - a set of types that model a discrete 
2-dimensional region concept.

# Exports

* Run   
* Region
"""
module Regions


#= ------------------------------------------------------------------------

    UnitRange{Int64}

------------------------------------------------------------------------ =#

import Base.-, Base.+, Base.contains, Base.∈
export invert, translate, +, -
export transpose, contains, isoverlapping, istouching, isclose

"""
    invert(x::UnitRange{Int64})

Inverts a range. Inversion mirrors a range at the origin. A range is 
inverted by reversing and inverting each of its coordinates.

```jldoctest
julia> using Regions

julia> invert(5:10)
-10:-5

julia> invert(invert(0:100))
0:100
```
"""
invert(x::UnitRange{Int64}) = UnitRange(-x.stop : -x.start)

"""
    translate(x::UnitRange{Int64}, y::Integer)

Translate a range. Translation moves a range. A range is translated by adding 
an offset to each of its coordinates.

In addition to the translate method, you can also use the + or - operators
to translate a range.

```jldoctest
julia> using Regions

julia> translate(0:10, 5)
5:15

julia> (5:15) + 10
15:25

julia> 10 + (5:15)
15:25

julia> (5:15) - 10
-5:5
```
"""
translate(x::UnitRange{Int64}, y::Integer) = x + y
+(x::UnitRange{Int64}, y::Integer) = x.start + y : x.stop + y
+(x::Integer, y::UnitRange{Int64}) = x + y.start : x + y.stop
-(x::UnitRange{Int64}, y::Integer) = x.start - y : x.stop - y

"""
    contains(x::UnitRange{Int64}, y::Integer)

Test if range x contains value x.

In addition to the contains method, you can also use the ∈ operator.

```jldoctest
julia> using Regions

julia> contains(0:10, 5)
true

julia> contains(0:10, 15)
false

julia> 0 ∈ 0:10
true

julia> 100 ∈ 0:10
false
```
"""
contains(x::UnitRange{Int64}, y::Integer) = y ∈ x

"""
    isoverlapping(x::UnitRange{Int64}, y::UnitRange{Int64})

Test if two ranges overlap.

```jldoctest
julia> using Regions

julia> isoverlapping(0:10, 5:15)
true

julia> isoverlapping(0:10, 20:30)
false
```
"""
isoverlapping(x::UnitRange{Int64}, y::UnitRange{Int64}) = (x < y) ? (x.stop ≥ y.start) : (y.stop ≥ x.start)

"""
    istouching(x::UnitRange{Int64}, y::UnitRange{Int64})

Test if two ranges touch.

```jldoctest
julia> using Regions

julia> istouching(0:10, 11:21)
true

julia> istouching(0:10, 12:22)
false
```
"""
istouching(x::UnitRange{Int64}, y::UnitRange{Int64}) = (x < y) ? (x.stop+1 ≥ y.start) : (y.stop+1 ≥ x.start)

"""
    isclose(::UnitRange{Int64}x, ::UnitRange{Int64}y, distance::Integer)

Test if two ranges are close.

If distance == 0 this is the same as isoverlapping().
If distance == 1 this is the same as istouching().
If distance > 1 this is testing of closeness.
"""
isclose(x::UnitRange{Int64}, y::UnitRange{Int64}, distance::Integer) = (x < y) ? (x.stop+distance ≥ y.start) : (y.stop+distance ≥ x.start)


#= ------------------------------------------------------------------------

    Run

------------------------------------------------------------------------ =#

import Base.isempty, Base.isless, Base.transpose, Base.-, Base.+, Base.contains
export Run
export translate, +, -, transpose, contains, ϵ, isoverlapping, istouching, isclose
export isempty, isless, minkowski_addition, minkowski_subtraction

"""
    Run

A run is a (possibly partial) set of consecutive coordinates within a row of a 
region. It consists of a discrete row coordinate (of type Signed) and a range 
of discrete column coordinates (of type UnitRange{Int64}).

Runs specify a sort order: one run is smaller than the other if it starts
before the other run modeling the coordinates from left to right and top to 
bottom.
"""
struct Run
    row::Integer
    columns::UnitRange{Int64}
end

"""
    isempty(x::Run)

Discover whether the run is empty.

```jldoctest
julia> using Regions

julia> isempty(Run(1, 1:10))
false

julia> isempty(Run(2, 1:1))
false

julia> isempty(Run(3, 1:0))
true
```
"""
isempty(x::Run) = isempty(x.columns)

"""
    isless(x::Run, y::Run)

Compare two runs according to their natural sort order. First, their rows are compared,
and if they are equal, their column ranges are compared.

```jldoctest reg
julia> using Regions

julia> isless(Run(0, 1:10), Run(1, 0:10))
true

julia> isless(Run(1, 1:10), Run(1, 2:10))
true
```
"""
isless(x::Run, y::Run) = (x.row < y.row) || ((x.row == y.row) && (x.columns < y.columns))

"""
    invert(x::Run)

Invert a run. Inversions mirrors a run at the origin. A run is inverted by negating 
its row and inverting its columns.

In addition to the invert method, you can also use the unary - operator.

```jldoctest reg
julia> using Regions

julia> invert(Run(1, 20:30))
Run(-1, -30:-20)

julia> -Run(-1, -30:-20)
Run(1, 20:30)
```
"""
invert(x::Run) = -x
-(x::Run) = Run(-x.row, invert(x.columns))

"""
    translate(r::Run, x::Integer, y::Integer)
    translate(r::Run, a::Array{Int64, 1})

Translate a run. Translation moves a run. A run is translated by adding offsets to its row and 
columns.

In addition to the translate method, you can also use the + or - operators
to translate a run.

```jldoctest reg
julia> using Regions

julia> translate(Run(1, 20:30), 10, 20)
Run(21, 30:40)

julia> translate(Run(1, 2:3), [10, 20])
Run(21, 12:13)

julia> Run(1, 2:3) + [10, 20]
Run(21, 12:13)

julia> [1, 2] + Run(0, 0:10)
Run(2, 1:11)

julia> Run(0, 0:100) - [5, 25]
Run(-25, -5:95)
```
"""
translate(a::Run, x::Integer, y::Integer) = a + [x, y]
translate(a::Run, b::Array{Int64, 1}) = a + b
+(a::Run, b::Array{Int64, 1}) = Run(a.row + b[2], a.columns + b[1])
+(a::Array{Int64, 1}, b::Run) = Run(a[2] + b.row, a[1] + b.columns)
-(a::Run, b::Array{Int64, 1}) = Run(a.row - b[2], a.columns - b[1])

"""
    contains(r::Run, x::Integer, y::Integer)
    contains(r::Run, a::Array{Int64, 1})

Test if run r contains position (x, y).
"""
contains(r::Run, x::Integer, y::Integer) = (r.row == y) && contains(r.columns, x)
contains(r::Run, a::Array{Int64, 1}) = contains(r, a[1], a[2])
∈(r::Run, a::Array{Int64, 1}) = contains(r, a)

"""
    isoverlapping(x::Run, y::Run)

Test if two runs overlap.
"""
isoverlapping(x::Run, y::Run) = x.row == y.row && isoverlapping(x.columns, y.columns)

"""
    istouching(x::Run, y::Run)

Test if two runs touch.
"""
istouching(x::Run, y::Run) = abs(x.row - y.row) ≤ 1 && istouching(x.columns, y.columns)

"""
    isclose(x::Run, y::Run, distance::Integer)

Test if two runs are close.

If distance == 0 this is the same as isoverlapping().
If distance == 1 this is the same as istouching().
If distance > 1 this is testing of closeness.
"""
isclose(a::Run, b::Run, x::Integer, y::Integer) = abs(a.row - b.row) <= y && isclose(a.columns, b.columns, x)
isclose(a::Run, b::Run, distance::Array{Int64, 1}) = isclose(a, b, distance[1], distance[2])

"""
    minkowski_addition(x::Run, y::Run)

Minkowski addition for two runs.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_addition(x::Run, y::Run) = Run(x.row + y.row, x.start + y.start : x.stop + y.stop)

"""
    minkowski_subtraction(x::Run, y::Run)

Minkowski subtraction for two runs.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_subtraction(x::Run, y::Run) = Run(x.row + y.row, x.start + y.stop : x.stop + y.start)
# TODO check minkowski subtraction, code seems to be wrong


#= ------------------------------------------------------------------------

    Region

------------------------------------------------------------------------ =#

import Base.copy, Base.-, Base.union, Base.==
export Region
export copy, transpose, -, contains, translate, translate!, left, right, bottom, top
export center, center!, merge, union, intersection, difference
export moment00, moment01, moment10

"""
    Region

A region is a discrete set of coordinates in two-dimensional euclidean space.
"""
struct Region
    runs::Array{Run,1}
    complement::Bool
end

Region(runs::Array{Run,1}) = Region(runs, false)

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

Invert a region. Inversion mirrors a region at the origin. A region is inverted
by inverting each of its runs.
"""
function invert(x::Region)
    result = Region([], x.complement) # TODO how to reserve space?
    # iterating backwards maintains the correct sort order of the runs
    for i in [size(x.runs)[1]:-1:1]
        push!(result.runs, -x.runs[i])
    end
    return result
end
-(x::Region) = invert(x)

"""
    translate(r::Region, x::Integer, y::Integer)
    translate(r::Region, a::Array{Int64, 1})

Translate a region. Translation moves a region. A region is translated by translating each 
of it's runs. 
"""
function translate(r::Region, x::Integer, y::Integer)
    return translate!(copy(r), x, y)
end
translate(r::Region, a::Array{Int64, 1}) = translate(r, a[1], a[2])
+(x::Region, y::Array{Int64, 1}) = translate(x, y[1], y[2])
+(x::Array{Int64, 1}, y::Region) = translate(y, x[1], x[2])
-(x::Region, y::Array{Int64, 1}) = translate(x, -y[1], -y[2])
function translate!(r::Region, x::Integer, y::Integer)
    for i in [1, size(r.runs)[1]]
        r.runs[i] = translate(r.runs[i], x, y)
    end
    return r
end

"""
    contains(r::Region, x::Integer, y::Integer)
    contains(r::Region, a::Array{Int64, 1})

Test if region r contains position (x, y).
"""
contains(r::Region, x::Integer, y::Integer) = r.complement ? !any(run -> contains(run, x, y), r.runs) : any(run -> contains(run, x, y), r.runs)
contains(r::Region, a::Array{Int64, 1}) = contains(r, a[1], a[2])
∈(r::Region, a::Array{Int64, 1}) = contains(r, a)

function left(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert size(r.runs)[1]>0 "cannot calculate for empty regions"
    v = r.runs[1].columns.start
    for i in r.runs
        v = min(v, i.columns.start)
    end
    return v
end

function right(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert size(r.runs)[1]>0 "cannot calculate for empty regions"
    v = r.runs[1].columns.stop
    for i in r.runs
        v = max(v, i.columns.stop)
    end
    return v
end

function bottom(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert size(r.runs)[1]>0 "cannot calculate for empty regions"
    v = r.runs[1].row
    for i in r.runs
        v = min(v, i.row)
    end
    return v
end

function top(r::Region)
    @assert !r.complement "cannot calculate for infinite (complement) regions"
    @assert size(r.runs)[1]>0 "cannot calculate for empty regions"
    v = r.runs[1].row
    for i in r.runs
        v = max(v, i.row)
    end
    return v
end

function center(r::Region)
    x = -(left(r)+right(r))÷2
    y = -(bottom(r)+top(r))÷2
    result = Region([], r.complement)
    for run in r.runs
        append!(result.runs, translate(run, x, y))
    end
    return result
end

function center!(r::Region)
    x = -(left(r)+right(r))÷2
    y = -(bottom(r)+top(r))÷2
    for run in r.runs
        translate!(run, x, y)
    end
end

"""
    complement(x::Region)

Calculates the set-theoretic complement of a region.   
"""
complement(x::Region) = Region(copy(x.runs), !x.complement)

"""
    merge(a::Array{Run,1}, b::Array{Run,1})

Merge sorted vectors `a` and `b`. Assumes that `a` and `b` are sorted 
and does not check whether `a` or `b` are sorted. 
"""
function merge(a::Array{Run,1}, b::Array{Run,1})
    res = Array{Run,1}(undef, 0)
    i = 1
    j = 1
    while i <= size(a, 1)
        if j > size(b, 1)
            while i <= size(a, 1)
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
    while j <= size(b, 1)
        push!(res, b[j])
        j = j+1
    end
    return res
end

"""
    sort(a::Array{Run, 1})

Variant of sort that returns a sorted copy of a leaving a itself unmodified. This ensures that
runs are sorted after an operation that might have destroyed the sort order, such as 
downsampling.
"""
sort(a::Array{Run,1}) = sort(a)


"""
    sort!(a::Array{Run, 1})

Sort the vector a in place. This ensures that runs are sorted after an operation that might 
have destroyed the sort order, such as downsampling.
"""
sort!(a::Array{Run,1}) = sort!(a)

function pack!(a::Array{Run,1})
    read = 1
    write = 1
    while read <= size(a, 1)
        a[write] = a[read]
        read = read+1
        while read <= size(a, 1) && a[write].row == a[read].row && a[write].columns.stop > a[read].columns.start
            if a[read].columns.stop > a[write].columns.stop
                a[write].columns.stop = a[read].columns.stop
            end
            read = read+1
        end
        write = write+1
    end
    deleteat!(a, write:size(a,1))
end

"""
    union(a::Array{Run,1}, b::Array{Run,1})

Calculates the union of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function union(a::Array{Run,1}, b::Array{Run,1})
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

function intersect!(a::Array{Run,1})
    read = 1
    if read > size(a, 1)
        return
    end
    next = read+1
    write = read
    while next <= size(a, 1)
        if a[read].row != a[next].row
            read = next
            next = next+1
        else
            if a[next].columns.start > a[read].columns.stop
                read = next
                next = next+1
            else
                a[write] = Run(a[read].row, a[next].columns.start:min(a[read].columns.stop, a[next].columns.stop))
                if a[next].columns.stop < a[read].columns.stop
                    a[next] = a[read]
                end
                read = next
                next = next+1
                write = write+1
            end
        end
    end
    deleteat!(a, write:size(a,1))
end

"""
    intersection(a::Array{Run,1}, b::Array{Run,1})

Calculates the intersection of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function intersection(a::Array{Run,1}, b::Array{Run,1})
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
    difference(a::Array{Run,1}, b::Array{Run,1})

Calculates the difference of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function difference(a::Array{Run,1}, b::Array{Run,1})
    if size(a, 1) == 0
        return b
    end
    if size(b, 1) == 0
        return a
    end

    res = Array{Run,1}(undef, 0)

    # first_b and last_b form a range of chords in b that are in the same row
    first_b = findfirst(x -> x.row >= a[1].row, b)
    last_b = first_b
    if first_b != nothing
        last_b = findlast(x -> x.row == b[first_b].row, view(b, first_b:size(b, 1)))
    end

    for a_index in 1:size(a, 1)
        if first_b != nothing && a[a_index].row > b[first_b].row
            # update the range
            first_b = findfirst(x -> x.row >= a[a_index].row, b)
            last_b = first_b
            if first_b != nothing
                last_b = findlast(x -> x.row == b[first_b].row, view(b, first_b:size(b, 1)))
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
                    elseif b[i.columns.stop >= a[a_index].columns.stop]
                        a[a_index] = Run(a[a_index].row, a[a_index].columns.start:b[i].columns.start-1)
                    # overlap in the middle, split a_chord into two and continue
                    else
                        push!(res, Row(a[a_index].row, a[a_index].columns.start:b[i].columns.start-1))
                        a[a_index] = Row(a[a_index].row, b[i].columns.stop+1, a[a_index].columns.stop)
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
    minkowski_addition(a::Array{Run,1}, b::Array{Run,1})

Minkowski addition of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function minkowski_addition(a::Array{Run,1}, b::Array{Run,1})
    if size(a, 1) == 0
        return a
    end
    if size(b, 1) == 0
        return a
    end

    res = Array{Run,1}(undef, 0)

    for brun in b.runs
        r = Array{Run,1}(undef, 0)
        for arun in a.runs
            push!(r, minkowski_addition(arun, brun))
        end
        pack!(r)
        res = union(res, r)
    end

    return res
end

"""
    minkowski_subtraction(a::Array{Run,1}, b::Array{Run,1})

Minkowski subtraction of two sorted arrays of runs. The function assumes that the runs are sorted
but does not check this.
"""
function minkowski_subtraction(a::Array{Run,1}, b::Array{Run,1})
    if size(a, 1) == 0
        return a
    end
    if size(b, 1) == 0
        return a
    end

    res = Array{Run,1}(undef, 0)

    for brun in b.runs
        r = Array{Run,1}(undef, 0)
        for arun in a.runs
            push!(r, minkowski_subtraction(arun, brun))
        end
        pack!(r)
        res = intersection(res, r)
    end

    return res
end

"""
    dilation(a::Array{Run,1}, b::Array{Run,1})

Dilation of a with structuring element b. The function assumes that the runs are sorted
but does not check this.
"""
dilation(a::Array{Run,1}, b::Array{Run,1}) = minkowski_addition(a, transpose(b))

"""
    erosion(a::Array{Run,1}, b::Array{Run,1})

Erosion of a with structuring element b. The function assumes that the runs are sorted
but does not check this.
"""
erosion(a::Array{Run,1}, b::Array{Run,1}) = minkowski_subtraction(a, transpose(b))

"""
    minkowski_addition(a::Region, b::Region)

Minkowski addition of a with structuring element b. Both the region a and the structuring
element b are regions. The structuring element should be a region that is centered
on the origin. This function partially supports complement regions 
and uses DeMorgan's rules to eliminate the complement.    
"""
function minkowski_addition(a::Region, b::Region)
    if b.complement
        @assert false "cannot calculate minkowski_addition with infinite (complement) structuring elements"
    end

    if a.complement
        return Region(minkowski_subtraction(a.runs, b.runs), true)
    else
        return Region(minkowski_addition(a.runs, b.runs), false)
    end
end

"""
    minkowski_subtraction(a::Region, b::Region)

Minkowski subtraction of a with structuring element b. Both the region a and the structuring
element b are regions. The structuring element should be a region that is centered
on the origin. This function partially supports complement regions 
and uses DeMorgan's rules to eliminate the complement.    
"""
function minkowski_subtraction(a::Region, b::Region)
    if b.complement
        @assert false "cannot calculate minkowski_subtraction with infinite (complement) structuring elements"
    end

    if a.complement
        return Region(minkowski_addition(a.runs, b.runs), true)
    else
        return Region(minkowski_subtraction(a.runs, b.runs), false)
    end
end

"""
    dilation(a::Region, b::Region)

Dilation of a with structuring element b. Both the region a and the structuring
element b are regions. The structuring element should be a region that is centered
on the origin. This function partially supports complement regions 
and uses DeMorgan's rules to eliminate the complement.    
"""
function dilation(a::Region, b::Region)
    if b.complement
        @assert false "cannot calculate dilation with infinite (complement) structuring elements"
    end

    if a.complement
        return Region(erosion(a.runs, b.runs), true)
    else
        return Region(dilation(a.runs, b.runs), false)
    end
end

"""
    erosion(a::Region, b::Region)

Erosion of a with structuring element b. Both the region a and the structuring
element b are regions. The structuring element should be a region that is centered
on the origin. This function partially supports complement regions 
and uses DeMorgan's rules to eliminate the complement.    
"""
function erosion(a::Region, b::Region)
    if b.complement
        @assert false "cannot calculate erosion with infinite (complement) structuring elements"
    end

    if a.complement
        return Region(dilation(a.runs, b.runs), true)
    else
        return Region(erosion(a.runs, b.runs), false)
    end
end

"""
    opening(a::Region, b::Region)

Opening is implemented by an erosion followed by a minkowski addition. The structuring 
element should be a region that is centered on the origin. Structures smaller
than the structuring element are removed and the region boundaries are smoothed.
"""
function opening(a::Region, b::Region)
    return minkowski_addition(erosion(a, b), b)
end

"""
    closing(a::Region, b::Region)

Closing is implemented by a dilation followed by a minkowski subtraction. The structuring 
element should be a region that is centered on the origin. Gaps and holes
smaller than the structuring element are closed and the region boundaries are smoothed.
"""
function closing(a::Region, b::Region)
    return minkowski_subtraction(dilation(a, b), b)
end

"""
    morphgradient(a::Region, b::Region)

The morphological gradient is calculated by taking the difference of the dilated region 
and the eroded region. The structuring element should be a region that is centered on the origin. 
"""
function morphgradient(a::Region, b::Region)
    return difference(dilation(a, b), erosion(a, b))
end


#=
The following functions should go into blob or thresholding module
=#

function threshold(image, threshold)
    region = Region([], false) # TODO how to reserve space?    

    for row=1:size(image, 1)
        inside_object = false
        start_column = 0
        for column=1:size(image, 2)
            if (image[row, column] > threshold) # predicate
                if !inside_object
                    inside_object = true
                    start_column = column
                end
            else
                if inside_object
                    inside_object = false
                    push!(region.runs, Run(row, start_column:(column-1)))
                end
            end
        end
        # if still inside at the end of a line...
        if inside_object
            push!(region.runs, Run(row, start_column:size(image, 2)))
        end
    end

    return region
end

end # module
