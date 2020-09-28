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

import Base.isless, Base.transpose, Base.-, Base.+, Base.contains
export Run
export translate, +, -, transpose, contains, ϵ, isoverlapping, istouching, isclose
export isless, minkowski_addition, minkowski_subtraction
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
    row :: Integer
    columns :: UnitRange{Int64}
end

"""
    isless(x, y)

Compare two ranges according their natural order. The order is determined by
the start.
"""
isless(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = x.start < y.start

"""
    transpose(x)

Transpose a range. Transposition mirrors a range at the origin. A range is 
transposed by reversing, negating and adding one to each of its coordinates.
"""
transpose(x :: UnitRange{Int64}) = -x
-(x :: UnitRange{Int64}) = -x.stop : -x.start

"""
    translate(x, y)

Translate a range. Translation moves a range. A range is translated by adding 
an offset to each of its coordinates.
"""
translate(x :: UnitRange{Int64}, y :: Integer) = x + y
+(x :: UnitRange{Int64}, y :: Integer) = x.start + y : x.stop + y
+(x :: Integer, y :: UnitRange{Int64}) = x + y.start : x + y.stop
-(x :: UnitRange{Int64}, y :: Integer) = x.start - y : x.stop - y

"""
    contains(x :: UnitRange{Int64}, y :: Integer)

Test if range x contains value x.
"""
contains(x :: UnitRange{Int64}, y :: Integer) = (y ≥ x.start) && (y ≤ x.stop)
∈(x :: UnitRange{Int64}, y :: Integer) = contains(x, y)

"""
    isoverlapping(x, y)

Test if two ranges overlap.
"""
isoverlapping(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = (x < y) ? (x.stop ≥ y.start) : (y.stop ≥ x.start)

"""
    istouching(x, y)

Test if two ranges touch.
"""
istouching(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = (x < y) ? (x.stop+1 ≥ y.start) : (y.stop+1 ≥ x.start)

"""
    isclose(x, y, distance)

Test if two ranges are close.

If distance == 0 this is the same as isoverlapping().
If distance == 1 this is the same as istouching().
If distance > 1 this is testing of closeness.
"""
isclose(x :: UnitRange{Int64}, y :: UnitRange{Int64}, distance :: Integer) = (x < y) ? (x.stop+distance ≥ y.start) : (y.stop+distance ≥ x.start)

"""
    minkowski_addition(x, y)

Minkowski addition for two ranges.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_addition(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = x.start + y.start : x.stop + y.stop

"""
    minkowski_subtraction(x, y)

Minkowski subtraction for two ranges.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_subtraction(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = x.start + y.stop : x.stop + y.start

"""
    isless(x, y)

Compare two runs according their natural order.
"""
isless(x :: Run, y :: Run) = (x.row < y.row) || ((x.row == y.row) && (x.columns < y.columns))

"""
    transpose(x)

Transpose a run. Transposition mirrors a run at the origin. A range is transposed by negating 
its row and transposing its columns.
"""
transpose(x :: Run) = -x
-(x :: Run) = Run(-x.row, -x.columns)

"""
    translate(r, x, y)

Translate a run. Translation moves a run. A run is translated by adding offsets to its row and 
columns.
"""
translate(r :: Run, x :: Integer, y :: Integer) = r + [x, y]
translate(x :: Run, y :: Array{Int64, 1}) = x + y
+(x :: Run, y :: Array{Int64, 1}) = Run(x.row + y[1], x.columns + y[2])
+(x :: Array{Int64, 1}, y :: Run) = Run(y[1] + x.row, y[2] + x.columns)
-(x :: Run, y :: Array{Int64, 1}) = Run(x.row - y[1], x.columns - y[2])

"""
    contains(x :: Run, y :: Integer)

Test if run x contains value x.
"""
contains(r :: Run, x :: Integer, y :: Integer) = (r.row == y) && contains(r.columns, x)
contains(x :: Run, y :: Array{Int64, 1}) = contains(r, y[1], y[2])
∈(x :: Run, y :: Array{Int64, 1}) = contains(x, y)

"""
    isoverlapping(x, y)

Test if two runs overlap.
"""
isoverlapping(x :: Run, y :: Run) = x.row == y.row && isoverlapping(x.columns, y.columns)

"""
    istouching(x, y)

Test if two runs touch.
"""
istouching(x :: Run, y :: Run) = abs(x.row - y.row) ≤ 1 && istouching(x.columns, y.columns)

"""
    isclose(x, y, distance)

Test if two runs are close.

If distance == 0 this is the same as isoverlapping().
If distance == 1 this is the same as istouching().
If distance > 1 this is testing of closeness.
"""
isclose(a :: Run, b :: Run, x :: Integer, y :: Integer) = abs(a.row - b.row) <= y && isclose(a.columns, b.columns, x)
isclose(a :: Run, b :: Run, distance :: Array{Int64, 1}) = isclose(a, b, distance[1], distance[2])

"""
    minkowski_addition(x, y)

Minkowski addition for two runs.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_addition(x :: Run, y :: Run) = Run(x.row + y.row, x.start + y.start : x.stop + y.stop)

"""
    minkowski_subtraction(x, y)

Minkowski subtraction for two runs.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_subtraction(x :: Run, y :: Run) = Run(x.row + y.row, x.start + y.stop : x.stop + y.start)

#=
The following functions should go into blob module
=#

moment00(x :: Run) = length(x.columns)

function moment10(x :: Run)
    n = x.columns.stop
    j = x.columns.start
    return (n * (n + 1) - (j - 1) * j) / 2.0
end

moment01(x :: Run) = x.row * length(x.columns)


#= ------------------------------------------------------------------------

    Region

------------------------------------------------------------------------ =#

import Base.copy, Base.-
export Region
export copy, transpose, -
export moment00, moment01, moment10


"""
    Region

A region is a 
"""
struct Region
    runs :: Array{Run,1}
    complement :: Bool
end

Region(runs :: Array{Run,1}) = Region(runs, false)

"""
    copy(x :: Region)
    
Create a copy of a region.    
"""
copy(x :: Region) = Region(copy(x.runs), x.complement)

"""
    transpose(x::Region)

Transpose a region. Transposition mirrors a region at the origin. 
"""
function transpose(x :: Region)
    result = Region([], x.complement)
    # iterating backwards maintains the correct sort order of the runs
    for i in [size(x.runs)[1]:-1:1]
        append!(result.runs, -x.runs[i])
    end
    return result
end
-(x :: Region) = transpose(x)



#=
The following functions should go into blob module
=#

function moment00(x :: Region) 
    accu = 0
    for r in x.runs
        accu += moment00(r)
    end
    return accu
end

function moment10(x :: Region) 
    accu = 0
    for r in x.runs
        accu += moment10(r)
    end
    return accu
end

function moment01(x :: Region) 
    accu = 0
    for r in x.runs
        accu += moment01(r)
    end
    return accu
end



end # module
