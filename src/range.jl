#= ------------------------------------------------------------------------

    UnitRange{Int}

------------------------------------------------------------------------ =#

import Base: -, +, contains, ∈
export translate, -, +
export invert, contains, isoverlapping, istouching, isclose

"""
    translate(x::UnitRange{Int}, y::Integer)

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
translate(x::UnitRange{Int}, y::Integer) = x + y
+(x::UnitRange{Int}, y::Integer) = x.start + y : x.stop + y
+(x::Integer, y::UnitRange{Int}) = x + y.start : x + y.stop
-(x::UnitRange{Int}, y::Integer) = x.start - y : x.stop - y

"""
    invert(x::UnitRange{Int})

Invert a range. Inversion mirrors a range at the origin. A range is 
inverted by reversing and inverting each of its coordinates.

In addition to the invert method, you can also use the - operator to
invert a range.

```jldoctest
julia> using Regions

julia> invert(5:10)
-10:-5

julia> invert(invert(0:100))
0:100
```
"""
invert(x::UnitRange{Int}) = UnitRange(-x.stop : -x.start)
-(x::UnitRange{Int}) = UnitRange(-x.stop : -x.start)

"""
    contains(x::UnitRange{Int}, y::Integer)

Test if range x contains value y.

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
contains(x::UnitRange{Int}, y::Integer) = y ∈ x
∈(x::UnitRange{Int}, y::Integer) = y ∈ x

"""
    isoverlapping(x::UnitRange{Int}, y::UnitRange{Int})

Test if two ranges overlap.

```jldoctest
julia> using Regions

julia> isoverlapping(0:10, 5:15)
true

julia> isoverlapping(0:10, 20:30)
false
```
"""
isoverlapping(x::UnitRange{Int}, y::UnitRange{Int}) = (x < y) ? (x.stop ≥ y.start) : (y.stop ≥ x.start)

"""
    istouching(x::UnitRange{Int}, y::UnitRange{Int})

Test if two ranges touch.

```jldoctest
julia> using Regions

julia> istouching(0:10, 11:21)
true

julia> istouching(0:10, 12:22)
false
```
"""
istouching(x::UnitRange{Int}, y::UnitRange{Int}) = (x < y) ? (x.stop+1 ≥ y.start) : (y.stop+1 ≥ x.start)

"""
    isclose(::UnitRange{Int}x, ::UnitRange{Int}y, distance::Integer)

Test if two ranges are close.

If distance == 0 this is the same as isoverlapping().
If distance == 1 this is the same as istouching().
If distance > 1 this is testing of closeness.

```jldoctest
julia> using Regions

julia> isclose(0:10, 15:25, 5)
true

julia> isclose(0:10, 15:25, 4)
false
```
"""
isclose(x::UnitRange{Int}, y::UnitRange{Int}, distance::Integer) = (x < y) ? (x.stop+distance ≥ y.start) : (y.stop+distance ≥ x.start)
