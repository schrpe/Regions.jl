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

import Base.isless, Base.-, Base.+, Base.contains
export Run
export translate, +, -, transpose, contains, isoverlapping, istouching, isclose
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
    row :: Signed
    columns :: UnitRange{Int64}
end

"""
     Compare two ranges according their natural start order.
"""
isless(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = x.start < y.start

"""
    Transpose a range.

    Transposition mirrors a range at the origin. A range is transposed by reversing, 
    negating and adding one to each of its coordinates.
"""
transpose(x :: UnitRange{Int64}) = -x.stop+1 : -x.start+1
-(x :: UnitRange{Int64}) = -x.stop+1 : -x.start+1

"""
    Translate a range.

    Translation moves a range. A range is translated by adding the offset to 
    each of its coordinates.
"""
translate(x :: UnitRange{Int64}, y :: Integer) = x.start + y : x.stop + y
+(x :: UnitRange{Int64}, y :: Integer) = x.start + y : x.stop + y
+(x :: Integer, y :: UnitRange{Int64}) = x + y.start : x + y.stop
-(x :: UnitRange{Int64}, y :: Integer) = x.start - y : x.stop - y
-(x :: Integer, y :: UnitRange{Int64}) = x - y.start : x - y.stop

"""
    Test if value is contained in range.
"""
contains(x :: UnitRange{Int64}, y :: Integer) = (y ≥ x.start) && (y ≤ x.stop)

"""
    Test if two ranges overlap.
"""
isoverlapping(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = (x < y) ? (x.stop ≥ y.start) : (y.stop ≥ x.start)

"""
    Test if two ranges touch.
"""
istouching(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = (x < y) ? (x.stop+1 ≥ y.start) : (y.stop+1 ≥ x.start)

"""
    Test if two ranges are close.

If distance == 0 this is the same as are_overlapping().
If distance == 1 this is the same as are_touching().
If distance > 1 this is testing of closeness.
"""
isclose(x :: UnitRange{Int64}, y :: UnitRange{Int64}, distance :: Integer) = (x < y) ? (x.stop+distance ≥ y.start) : (y.stop+distance ≥ x.start)

"""
    Minkowski addition for two ranges.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_addition(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = x.start + y.start : x.stop + y.stop

"""
    Minkowski subtraction for two ranges.

This is a building block for region-based morphology. It avoids
touching each item of a range and calculates the result only by
manipulating the range ends.
"""
minkowski_subtraction(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = (length(x) < length(y)) ? (0:-1) : (x.start + y.start + length(y) : x.start + y.start + length(x))



"""
     Compare two chords according their natural order.
"""
isless(x :: Run, y :: Run) = (x.row < y.row) || ((x.row == y.row) && (x.columns < y.columns))

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

import Base.isless
export Region
export isless
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
