#= ------------------------------------------------------------------------

    Run

------------------------------------------------------------------------ =#

import Base.isempty, Base.isless, Base.transpose, Base.-, Base.+, Base.contains
export Run
export translate, +, -, transpose, contains, ϵ, isoverlapping, istouching, isclose
export isempty, isless

"""
    Run

A run is a set of consecutive coordinates within a row (possibly partial) of a 
region. It consists of a discrete row coordinate (of type Signed) and a range 
of discrete column coordinates (of type UnitRange{Int64}).

Runs within a region specify a sort order: one run is smaller than the other if it starts
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
    translate(r::Run, a::Vector{Int64})

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
translate(a::Run, b::Vector{Int64}) = a + b
+(a::Run, b::Vector{Int64}) = Run(a.row + b[2], a.columns + b[1])
+(a::Vector{Int64}, b::Run) = Run(a[2] + b.row, a[1] + b.columns)
-(a::Run, b::Vector{Int64}) = Run(a.row - b[2], a.columns - b[1])

"""
    contains(r::Run, x::Integer, y::Integer)
    contains(r::Run, a::Vector{Int64})

Test if run r contains position (x, y).
"""
contains(r::Run, x::Integer, y::Integer) = (r.row == y) && contains(r.columns, x)
contains(r::Run, a::Vector{Int64}) = contains(r, a[1], a[2])
∈(r::Run, a::Vector{Int64}) = contains(r, a)

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
    isclose(a::Run, b::Run, x::Integer, y::Integer)
    isclose(a::Run, b::Run, d::Integer)
    isclose(x::Run, y::Run, distance::Vector[Int64])

Test if two runs are close.

If distance == 0 this is the same as isoverlapping().
If distance == 1 this is the same as istouching().
If distance > 1 this is testing of closeness.
"""
isclose(a::Run, b::Run, x::Integer, y::Integer) = abs(a.row - b.row) <= y && isclose(a.columns, b.columns, x)
isclose(a::Run, b::Run, d::Integer) = isclose(a, b, d, d)
isclose(a::Run, b::Run, distance::Vector{Int64}) = isclose(a, b, distance[1], distance[2])
