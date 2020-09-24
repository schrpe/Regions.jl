"""
    Regions

    Main module for Regions.jl - a set of types that model a discrete 2-dimensional region concept.

# Exports

* Chord   
* Region
"""module Regions


#= ------------------------------------------------------------------------

    Chord

------------------------------------------------------------------------ =#

import Base.isless
export Chord
export isless
export moment00, moment01, moment10

"""
    Chord

A chord is a (possibly partial) scan along a row of a region. It consists of a 
discrete row coordinate (of type Signed) and a range of discrete column 
coordinates (of type UnitRange{Int64}).

Chords specify a sort order. One chord is smaller than the other if it starts
before the other chord modeling the coordinates from left to right and top to 
bottom.
"""
struct Chord
    row :: Signed
    columns :: UnitRange{Int64}
end

"""
     Compare two ranges according their natural start order.
"""
isless(x :: UnitRange{Int64}, y :: UnitRange{Int64}) = x.start < y.start

"""
     Compare two chords according their natural order.
"""
isless(x :: Chord, y :: Chord) = (x.row < y.row_) || ((x.row == y.row) && (x.columns < y.columns))

#=
The following functions should go into blob module
=#

moment00(x :: Chord) = length(x.columns)

function moment10(x :: Chord)
    n = x.columns.stop
    j = x.columns.start
    return (n * (n + 1) - (j - 1) * j) / 2.0
end

moment01(x :: Chord) = x.row * length(x.columns)


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
    runs :: Array{Chord,1}
    complement :: Bool
end

#=
The following functions should go into blob module
=#

moment00(x :: Region) = mapreduce(moment00, +, x.runs, 0)



end # module
