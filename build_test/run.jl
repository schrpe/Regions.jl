#= ------------------------------------------------------------------------

    Run

------------------------------------------------------------------------ =#

import Base: isempty, isless, -, +, contains, ∈
export Run
export isempty, isless, invert
export translate, -, +
export contains, isoverlapping, istouching, isclose

"""
    Run

A run is a set of consecutive coordinates within a column (possibly partial) of a
region. It consists of a discrete column coordinate (of type Int) and a range
of discrete row coordinates (of type UnitRange{Int64}).

Runs within a region specify a sort order: one run is smaller than the other if it starts
before the other run modeling the coordinates from left to right and top to
bottom.
"""
struct Run
    column::Int
    rows::UnitRange{Int64}
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
isempty(x::Run) = isempty(x.rows)

"""
    isless(x::Run, y::Run)

Compare two runs according to their natural sort order. First, their columns are compared,
and if they are equal, their row ranges are compared.

```jldoctest reg
julia> using Regions

julia> isless(Run(0, 1:10), Run(1, 0:10))
true

julia> isless(Run(1, 1:10), Run(1, 2:10))
true
```
"""
isless(x::Run, y::Run) = (x.column < y.column) || ((x.column == y.column) && (x.rows < y.rows))

"""
    invert(x::Run)
    -(x::Run) = invert(x)

Invert a run. Inversion mirrors a run at the origin. A run is inverted by negating
its column and inverting its rows.

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
-(x::Run) = Run(-x.column, invert(x.rows))

"""
    translate(r::Run, x::Integer, y::Integer)
    translate(r::Run, a::Vector{Int64})

Translate a run. Translation moves a run. A run is translated by adding offsets to its
column and rows.

In addition to the translate method, you can also use the + or - operators
to translate a run.

```jldoctest reg
julia> using Regions

julia> translate(Run(1, 20:30), 10, 20)
Run(11, 40:50)

julia> translate(Run(3, 2:5), [4, 10])
Run(7, 12:15)

julia> Run(3, 2:5) + [4, 10]
Run(7, 12:15)

julia> [4, 3] + Run(0, 0:10)
Run(4, 3:13)

julia> Run(0, 0:100) - [5, 25]
Run(-5, -25:75)
```
"""
translate(a::Run, x::Integer, y::Integer) = a + [x, y]
translate(a::Run, b::Vector{Int64}) = a + b
+(a::Run, b::Vector{Int64}) = Run(a.column + b[1], a.rows + b[2])
+(a::Vector{Int64}, b::Run) = Run(a[1] + b.column, a[2] + b.rows)
-(a::Run, b::Vector{Int64}) = Run(a.column - b[1], a.rows - b[2])

"""
    contains(r::Run, x::Integer, y::Integer)
    contains(r::Run, a::Vector{Int64})

Test if run r contains position (x, y).

```jldoctest reg
julia> using Regions

julia> contains(Run(7, 2:8), 7, 5)
true

julia> contains(Run(7, 2:8), 7, 10)
false

julia> contains(Run(7, 2:8), 3, 5)
false
```
"""
contains(r::Run, x::Integer, y::Integer) = (r.column == x) && contains(r.rows, y)
contains(r::Run, a::Vector{Int64}) = contains(r, a[1], a[2])
∈(a::Vector{Int64}, r::Run) = contains(r, a)

"""
    isoverlapping(x::Run, y::Run)

Test if two runs overlap.

```jldoctest
julia> using Regions

julia> isoverlapping(0:10, 5:15)
true

julia> isoverlapping(0:10, 20:30)
false
```
"""
isoverlapping(x::Run, y::Run) = x.column == y.column && isoverlapping(x.rows, y.rows)

"""
    istouching(x::Run, y::Run)

Test if two runs touch.

```jldoctest
julia> using Regions

julia> istouching(Run(5, 0:10), Run(6, 5:15))
true

julia> istouching(Run(5, 0:10), Run(7, 5:15))
false
```
"""
istouching(x::Run, y::Run) = abs(x.column - y.column) ≤ 1 && istouching(x.rows, y.rows)

"""
    isclose(a::Run, b::Run, x::Integer, y::Integer)
    isclose(a::Run, b::Run, d::Integer)
    isclose(x::Run, y::Run, distance::Vector{Int64})

Test if two runs are close.

If distance == 0 this is the same as isoverlapping().
If distance == 1 this is the same as istouching().
If distance > 1 this is testing of closeness.

```jldoctest
julia> using Regions

julia> isclose(Run(5, 0:10), Run(8, 2:15), 5, 3)
true

julia> isclose(Run(5, 0:10), Run(8, 15:20), 2, 2)
false
```
"""
isclose(a::Run, b::Run, x::Integer, y::Integer) = abs(a.column - b.column) <= x && isclose(a.rows, b.rows, y)
isclose(a::Run, b::Run, d::Integer) = isclose(a, b, d, d)
isclose(a::Run, b::Run, distance::Vector{Int64}) = isclose(a, b, distance[1], distance[2])
