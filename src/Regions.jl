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

    Run

------------------------------------------------------------------------ =#

import Base.isless, Base.transpose, Base.-, Base.+, Base.contains, Base.isempty
export Run
export translate, +, -, transpose, contains, ϵ, isoverlapping, istouching, isclose
export isempty, isless, minkowski_addition, minkowski_subtraction
export moment00, moment01, moment10

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

isempty(x::UnitRange{Int64}) = x.stop < x.start

"""
    isless(x::UnitRange{Int64}, y::UnitRange{Int64})

Compare two ranges according their natural order. The order is determined by
the start.
"""
isless(x::UnitRange{Int64}, y::UnitRange{Int64}) = x.start < y.start

"""
    transpose(x::UnitRange{Int64})

Transpose a range. Transposition mirrors a range at the origin. A range is 
transposed by reversing, negating and adding one to each of its coordinates.
"""
transpose(x::UnitRange{Int64}) = -x
-(x::UnitRange{Int64}) = -x.stop : -x.start

"""
    translate(x::UnitRange{Int64}, y::Integer)

Translate a range. Translation moves a range. A range is translated by adding 
an offset to each of its coordinates.
"""
translate(x::UnitRange{Int64}, y::Integer) = x + y
+(x::UnitRange{Int64}, y::Integer) = x.start + y : x.stop + y
+(x::Integer, y::UnitRange{Int64}) = x + y.start : x + y.stop
-(x::UnitRange{Int64}, y::Integer) = x.start - y : x.stop - y

"""
    contains(x::UnitRange{Int64}, y::Integer)

Test if range x contains value x.
"""
contains(x::UnitRange{Int64}, y::Integer) = (y ≥ x.start) && (y ≤ x.stop)
∈(x::UnitRange{Int64}, y::Integer) = contains(x, y)

"""
    isoverlapping(x::UnitRange{Int64}, y::UnitRange{Int64})

Test if two ranges overlap.
"""
isoverlapping(x::UnitRange{Int64}, y::UnitRange{Int64}) = (x < y) ? (x.stop ≥ y.start) : (y.stop ≥ x.start)

"""
    istouching(x::UnitRange{Int64}, y::UnitRange{Int64})

Test if two ranges touch.
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

"""
    minkowski_addition(x::UnitRange{Int64}, y::UnitRange{Int64})

Minkowski addition for two ranges.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_addition(x::UnitRange{Int64}, y::UnitRange{Int64}) = x.start + y.start : x.stop + y.stop

"""
    minkowski_subtraction(x::UnitRange{Int64}, y::UnitRange{Int64})

Minkowski subtraction for two ranges.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_subtraction(x::UnitRange{Int64}, y::UnitRange{Int64}) = x.start + y.stop : x.stop + y.start

isempty(x::Run) = isempty(x.columns)


"""
    isless(x::Run, y::Run)

Compare two runs according their natural order.
"""
isless(x::Run, y::Run) = (x.row < y.row) || ((x.row == y.row) && (x.columns < y.columns))

"""
    transpose(x::Run)

Transpose a run. Transposition mirrors a run at the origin. A range is transposed by negating 
its row and transposing its columns.
"""
transpose(x::Run) = -x
-(x::Run) = Run(-x.row, -x.columns)

"""
    translate(r::Run, x::Integer, y::Integer)

Translate a run. Translation moves a run. A run is translated by adding offsets to its row and 
columns.
"""
translate(r::Run, x::Integer, y::Integer) = r + [x, y]
translate(x::Run, y::Array{Int64, 1}) = x + y
+(x::Run, y::Array{Int64, 1}) = Run(x.row + y[1], x.columns + y[2])
+(x::Array{Int64, 1}, y::Run) = Run(y[1] + x.row, y[2] + x.columns)
-(x::Run, y::Array{Int64, 1}) = Run(x.row - y[1], x.columns - y[2])

"""
    contains(r::Run, x::Integer, y::Integer)

Test if run x contains position x, y.
"""
contains(r::Run, x::Integer, y::Integer) = (r.row == y) && contains(r.columns, x)
contains(x::Run, y::Array{Int64, 1}) = contains(r, y[1], y[2])
∈(x::Run, y::Array{Int64, 1}) = contains(x, y)

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

#=
The following functions should go into blob module
=#

moment00(x::Run) = length(x.columns)

function moment10(x::Run)
    n = x.columns.stop
    j = x.columns.start
    return (n * (n + 1) - (j - 1) * j) / 2.0
end

moment01(x::Run) = x.row * length(x.columns)


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

A region is a 
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
    transpose(x::Region)

Transpose a region. Transposition mirrors a region at the origin. 
"""
function transpose(x::Region)
    result = Region([], x.complement)
    # iterating backwards maintains the correct sort order of the runs
    for i in [size(x.runs)[1]:-1:1]
        append!(result.runs, -x.runs[i])
    end
    return result
end
-(x::Region) = transpose(x)

"""
    contains(r::Region, x::Integer, y::Integer)

Test if region x contains position x, y.
"""
contains(r::Region, x::Integer, y::Integer) = r.complement ? !any(run -> contains(run, x, y), r.runs) : any(run -> contains(run, x, y), r.runs)
contains(x::Region, y::Array{Int64, 1}) = contains(x, y[1], y[2])
∈(x::Region, y::Array{Int64, 1}) = contains(x, y)

"""
    translate(r::Region, x::Integer, y::Integer)

Translate a region. Translation moves a region. A region is translated by translating each 
of it's runs. 
"""
function translate(r::Region, x::Integer, y::Integer)
    return translate!(copy(r), x, y)
end
translate(x::Region, y::Array{Int64, 1}) = translate(x, y[1], y[2])
+(x::Region, y::Array{Int64, 1}) = translate(x, y[1], y[2])
+(x::Array{Int64, 1}, y::Region) = translate(y, x[1], x[2])
-(x::Region, y::Array{Int64, 1}) = translate(x, -y[1], -y[2])
function translate!(r::Region, x::Integer, y::Integer)
    for i in [1, size(r.runs)[1]]
        r.runs[i] = translate(r.runs[i], x, y)
    end
    return r
end

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

function union(a::Array{Run,1}, b::Array{Run,1})
    res = merge(a, b)
    pack!(res)
    return res
end

function union(a::Region, b::Region)
    return Region(union(a.runs, b.runs), false)
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

function intersection(a::Array{Run,1}, b::Array{Run,1})
    res = merge(a, b)
    intersect!(res)
    return res
end

function intersection(a::Region, b::Region)
    return Region(intersection(a.runs, b.runs), false)
end

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

function difference(a::Region, b::Region)
    return Region(difference(a.runs, b.runs), false)
end

#=
The following functions should go into blob module
=#

function moment00(x::Region) 
    accu = 0
    for r in x.runs
        accu += moment00(r)
    end
    return accu
end

function moment10(x::Region) 
    accu = 0
    for r in x.runs
        accu += moment10(r)
    end
    return accu
end

function moment01(x::Region) 
    accu = 0
    for r in x.runs
        accu += moment01(r)
    end
    return accu
end



end # module
