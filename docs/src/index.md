```@meta
CurrentModule = Regions
```

# Regions

Documentation for [Regions](https://github.com/schrpe/Regions.jl).

Regions.jl defines a set of types and functions that model a discrete 2-dimensional region concept. 

![Example of a region](region.svg)

In order to use the types and functions defined in the Regions package, you must first install it with the package manager and then make it known to your module:

```julia
julia> using Pkg
julia> Pkg.add("Regions")
```
```jldoctest reg
julia> using Regions
```

Regions can be used for various purposes in machine vision and image processing. Since they provide an efficient run-length encoding of binary images, they avoid the need to touch every pixel when doing binary morphology and thus enable substantial speedup of such operations. Regions are also the basis for binary blob analysis, where the calculation of shape-based features is substantially accelerated because of the run-length encoding. Finally, regions can be used as the domain of image processing functions.

## Contents

```@contents
```

## Introduction

A region can be seen as a set of discrete coordinates in the cartesian plane. In fact, one of the main motivations for the region concept was to model a set of pixel locations for image processing purposes.

A region is represented with a sorted list of vertical runs. Runs themselves are represented with a column coordinate and a range of vertical row coordinates.

**Coordinate convention.** The horizontal axis is called *column* (x) and increases to the right. The vertical axis is called *row* (y) and increases downward, following Julia's matrix convention (`img[row, column]`). Consequently, `bottom(r)` returns the minimum row value — the row closest to the top of an image — and `top(r)` returns the maximum row value.

![Region and runs](region_and_runs.svg)

Here is how this region can be created using the Julia REPL. Each `Run(column, rows)` specifies a vertical span of pixels in a given column:

```jldoctest reg
julia> Region([Run(0, 1:4), Run(1, 0:5), Run(2, 1:2), Run(2, 4:6), Run(3, 1:2), Run(3, 5:5), Run(4, 1:2), Run(4, 4:5), Run(5, 2:4)])
Region(Run[Run(0, 1:4), Run(1, 0:5), Run(2, 1:2), Run(2, 4:6), Run(3, 1:2), Run(3, 5:5), Run(4, 1:2), Run(4, 4:5), Run(5, 2:4)], false)
```

In order to explain how a region is built, we start with the innermost element, the range. We continue with the run, and finally we end with a region, which essentially is a sorted vector of runs. We build our understanding of regions bottom up, before we finally explain some usage scenarios of regions.

### Range

The most basic building block of a region is a range. The `UnitRange{Int64}` is a suitable type and can be written like this:

```jldoctest reg
julia> 0:99
0:99

julia> (0:99).start
0

julia> (0:99).stop
99

julia> length(0:99)
100

julia> length(-50:50)
101
```

A range where the stop is less than the start is considered empty.

```jldoctest reg
julia> isempty(0:0)
false

julia> isempty(1:0)
true
```

The natural sort order of ranges is to sort them by their start.

```jldoctest reg
julia> 0:100 < 1:101
true

julia> 0:1 < 1:100
true

julia> 0:50 < 0:100
true

julia> isless(0:100, 1:101)
true
```

Inversion mirrors a range at the origin.

```jldoctest reg
julia> invert(0:100)
-100:0

julia> invert(invert(5:10))
5:10
```

Translation moves a range by an offset.

```jldoctest reg
julia> translate(0:100, 50)
50:150

julia> (10:20) + 30
40:50

julia> 10 + (20:30)
30:40

julia> (50:100) - 10
40:90
```

You can check whether a value is contained in a range.

```jldoctest reg
julia> contains(10:20, 10)
true

julia> contains(10:20, 15)
true

julia> contains(10:20, 20)
true

julia> contains(10:20, 9)
false

julia> 14 ∈ 10:20
true
```

Two ranges can overlap or touch.

```jldoctest reg
julia> isoverlapping(10:20, 5:25)
true

julia> isoverlapping(0:0, 1:1)
false

julia> istouching(0:0, 1:1)
true

julia> istouching(0:0, 2:2)
false
```

### Run

A run combines a column coordinate with a range of vertical row coordinates.

An empty run is a run whose rows range is empty.

```jldoctest reg
julia> isempty(Run(0, 0:-1))
true

julia> isempty(Run(0, 0:100))
false
```

The natural sort order of runs is to sort them by their column, then by their rows range.

```jldoctest reg
julia> Run(0, 0:100) < Run(1, 0:100)
true

julia> Run(0, 0:100) < Run(0, 1:101)
true
```

Inversion mirrors a run at the origin, in both the horizontal and vertical directions.

```jldoctest reg
julia> invert(Run(10, 50:100))
Run(-10, -100:-50)

julia> invert(invert(Run(1, 5:10)))
Run(1, 5:10)
```

Translation moves a run by horizontal and vertical offsets.

```jldoctest reg
julia> translate(Run(0, 0:100), 10, 20)
Run(10, 20:120)

julia> Run(0, 10:20) + [30, 40]
Run(30, 50:60)

julia> Run(0, 10:20) - [30, 40]
Run(-30, -30:-20)
```

Two runs can overlap or touch. They can only overlap if they share the same column.

```jldoctest reg
julia> isoverlapping(Run(3, 0:10), Run(3, 5:15))
true

julia> isoverlapping(Run(3, 0:10), Run(4, 0:10))
false

julia> istouching(Run(3, 0:10), Run(4, 5:15))
true

julia> istouching(Run(3, 0:10), Run(5, 5:15))
false
```

### Region

A region is a subset of the discrete two-dimensional space. It represents a set (in the sense of mathematical set theory) of discrete coordinates. A region may be finite or infinite. A region may not be connected and it may contain holes.

![Examples of regions](regions.png)

Examples of regions: two simple regions, a region with a hole and a region consisting of two parts.

Regions are an essential concept in computer vision and are useful in many respects.

Regions are not necessarily related to images; they can exist independently and without images. In addition, the coordinate space is not confined to the bounds of an image, and regions can extend into the quadrants with negative coordinates in the two-dimensional space.

Regions can be built in various ways: 
* programatically by building and adding runs,
* with functions that construct specific forms of regions,
* by segmentation of an image.

As already mentioned above, regions consist of a vector of sorted runs. Many functions depend on these sorted runs. Whenever the runs are not sorted, these functions will not work properly. You must therefore make sure that you keep the runs sorted whenever you directly manipulate the runs vector. One way to keep the runs sorted is to call the sort! function to sort the runs in place.

```jldoctest reg
julia> reg = Region([Run(0, -2:2), Run(1, 0:0), Run(-1, 0:0), Run(2, 0:0), Run(-2, 0:0)])
Region(Run[Run(0, -2:2), Run(1, 0:0), Run(-1, 0:0), Run(2, 0:0), Run(-2, 0:0)], false)

julia> sort!(reg.runs)
5-element Vector{Run}:
 Run(-2, 0:0)
 Run(-1, 0:0)
 Run(0, -2:2)
 Run(1, 0:0)
 Run(2, 0:0)

julia> reg
Region(Run[Run(-2, 0:0), Run(-1, 0:0), Run(0, -2:2), Run(1, 0:0), Run(2, 0:0)], false)
```

#### Build regions from runs

Here is an example of a very simple 5×5 cross shaped region, centered on the origin. It uses a vertical run for column 0 (spanning rows −2 to 2) and single-pixel runs at row 0 for columns −2, −1, 1, and 2:

```jldoctest reg
julia> Region([Run(-2, 0:0), Run(-1, 0:0), Run(0, -2:2), Run(1, 0:0), Run(2, 0:0)])
Region(Run[Run(-2, 0:0), Run(-1, 0:0), Run(0, -2:2), Run(1, 0:0), Run(2, 0:0)], false)
```

If you build regions this way, you must ensure that the runs are properly sorted, otherwise many functions will not work properly. An easy way to ensure that the runs are sorted is to call sort on the runs vector.

```jldoctest reg
julia> Region(sort([Run(0, -2:2), Run(1, 0:0), Run(-1, 0:0), Run(2, 0:0), Run(-2, 0:0)]))
Region(Run[Run(-2, 0:0), Run(-1, 0:0), Run(0, -2:2), Run(1, 0:0), Run(2, 0:0)], false)
```

#### Build regions from geometry

Regions can be created from simple geometric forms. `region_from_box` creates a filled rectangular region from its bounding box coordinates. The four arguments are `left`, `top`, `right`, `bottom`, where `top` > `bottom` and `right` > `left`.

```jldoctest reg
julia> box = region_from_box(1, 4, 3, 1)
Region(Run[Run(1, 1:4), Run(2, 1:4), Run(3, 1:4)], false)

julia> bounds(box)
(1, 4, 3, 1)

julia> contains(box, 2, 3)
true

julia> contains(box, 0, 3)
false
```

The result contains one vertical run per column, each spanning from `bottom` to `top`.

`region_from_polygon` creates a filled region from an arbitrary polygon given as a vector of
`(column, row)` vertex pairs, in clockwise or counter-clockwise order.

```jldoctest reg
julia> tri = region_from_polygon([(0,0), (4,0), (2,4)]);

julia> length(tri.runs)
4

julia> contains(tri, 2, 2)
true
```

`region_from_circle` creates a filled circular region from a center point and radius. All
integer coordinates within the circle (satisfying `(x−cx)² + (y−cy)² ≤ r²`) are included.

```jldoctest reg
julia> c = region_from_circle(0, 0, 3);

julia> contains(c, 0, 3)
true

julia> contains(c, 2, 2)
true

julia> contains(c, 3, 3)
false
```

#### Build regions by segmentation

Image segmentation turns a grayscale image into a region by applying a predicate to each pixel. Pixels for which the predicate returns `true` become part of the region.

`Regions` extends `Images.binarize` with a predicate-based method rather than defining a competing function. Julia's dispatch selects the correct method by the second argument type: a `Function` argument routes to the `Regions` method and returns a `Region`; an algorithm object such as `Otsu()` routes to the `Images` method unchanged. Because both packages export the same underlying function, loading both with `using` raises no ambiguity warning.

```jldoctest reg
julia> img = [0.0 1.0 0.0; 0.0 1.0 0.0; 0.0 1.0 0.0];

julia> seg = binarize(img, px -> px > 0.5);

julia> length(seg.runs)
1

julia> seg.runs[1]
Run(2, 1:3)
```

Here the 3×3 image has bright pixels only in column 2, producing a single run spanning all three rows. Real-world usage typically loads a grayscale image from disk and segments it:

```julia
using FileIO, ImageIO, ImageMagick
img = load("gear.png")
reg = binarize(img, px -> px < 0.9)
```

The grayscale image of the gear is binarized, i.e. all pixels below 90 % brightness are contained in the region.

![Segmented gear](threshold.png)

## Set Operations

The three classical set operations — `union`, `intersection`, and `difference` — are the primary
tools for combining regions. Because a region is a set of discrete pixel coordinates, these
operations have exactly the meaning from mathematical set theory: each pixel either belongs or
does not belong to a region, and the operations determine membership in the result accordingly.

All three operations handle complement regions transparently via De Morgan's laws.
`union(invert(a), invert(b))` returns `invert(intersection(a, b))`, and so on, so regular and
complement regions can be freely mixed without special-casing.

### Union

`union(a, b)` returns every pixel that belongs to *at least one* of the two regions — the
pixel-wise logical OR. Pixels exclusive to `a`, pixels exclusive to `b`, and pixels in the
overlap all appear in the result.

```jldoctest reg
julia> a = region_from_box(0, 3, 4, 0);  # 5 columns × 4 rows = 20 pixels

julia> b = region_from_box(3, 5, 7, 2);  # 5 columns × 4 rows = 20 pixels, partly overlapping

julia> u = union(a, b);

julia> area(u)                            # 20 + 20 − 4 pixels of overlap
36

julia> contains(u, 1, 1)                 # inside a only
true

julia> contains(u, 6, 4)                 # inside b only
true

julia> contains(u, 4, 3)                 # inside both
true
```

`union` is commutative (`union(a,b) == union(b,a)`) and associative, so combining more than two
regions with `union` can be done in any order.

Typical uses: merging two separately segmented foreground regions, filling the gap between two
adjacent blobs, or stitching together partial results from parallel segmentation passes.

### Intersection

`intersection(a, b)` keeps only pixels that are present in *both* regions simultaneously — the
pixel-wise logical AND. Pixels that belong exclusively to `a` or exclusively to `b` are dropped.

```jldoctest reg
julia> i = intersection(a, b);

julia> area(i)                            # only the 2×2 overlap at columns 3–4, rows 2–3
4

julia> contains(i, 4, 3)                 # in both a and b
true

julia> contains(i, 1, 1)                 # in a only — excluded
false
```

A common pattern is *masking*: intersecting a segmented region with a geometrically defined
region of interest (a circle, a box, a polygon) restricts analysis to a specific area without
re-running segmentation.

```jldoctest reg
julia> roi = region_from_circle(2, 2, 3);  # circular region of interest

julia> masked = intersection(u, roi);      # restrict the union result to the ROI

julia> area(masked) <= area(u)
true
```

### Difference

`difference(a, b)` returns all pixels of `a` that are *not* in `b`. The operation is
asymmetric: swapping the operands generally yields a different result.

```jldoctest reg
julia> d = difference(a, b);

julia> area(d)                            # 20 − 4 overlapping pixels
16

julia> contains(d, 1, 1)                 # in a, not in b
true

julia> contains(d, 4, 3)                 # in both — excluded
false

julia> area(difference(b, a))            # subtract a from b instead
16
```

Difference is used to punch holes in a region (subtract a reference shape or a known background
area) or to isolate the part of one region not covered by another.

### Combining Operations

The three operations compose freely. A common idiom is to build a complex shape from simple
geometric primitives by alternating union and difference:

```jldoctest reg
julia> disk   = region_from_circle(0, 0, 10);

julia> hub    = region_from_circle(0, 0, 3);

julia> notch  = region_from_box(-1, 11, 1, 7);   # rectangular notch at the top

julia> ring_with_notch = difference(difference(disk, hub), notch);

julia> area(ring_with_notch) < area(disk)
true

julia> !contains(ring_with_notch, 0, 0)           # hub removed
true

julia> !contains(ring_with_notch, 0, 9)           # notch removed
true
```

### Gear Example

Building on the segmentation from the previous section, set operations refine the gear region
into analysis-ready sub-regions. A hub circle and an outer boundary circle are created
geometrically and combined with the segmented gear via `difference` and `intersection`:

```julia
using FileIO, ImageIO, ImageMagick

img  = load("gear.png")
gear = binarize(img, px -> px < 0.9)

# Approximate center and radii determined from the image dimensions (pixels)
cx, cy       = 256, 256
hub_radius   = 28
outer_radius = 240

# Remove the solid center hub — what remains are the gear teeth and body
hub        = region_from_circle(cx, cy, hub_radius)
teeth_only = difference(gear, hub)

# Trim any noise or partial pixels outside the outer gear boundary
outline       = region_from_circle(cx, cy, outer_radius)
teeth_trimmed = intersection(teeth_only, outline)

# Isolate the hub area separately for independent measurement
hub_region = intersection(gear, hub)
```

The three resulting regions — `teeth_trimmed`, `hub_region`, and the full `gear` — can now be
passed independently to area measurement, moment computation, or morphological analysis.

| Full gear | Teeth only | Hub only |
|:---------:|:----------:|:--------:|
| ![Full gear region](gear_full.png) | ![Teeth region](gear_teeth.png) | ![Hub region](gear_hub.png) |

Each image shows the segmented region in white against the darkened original photograph.
The teeth image has the inner hub circle removed via `difference`; the hub image retains
only the inner disc via `intersection`.

## Reference

```@autodocs
Modules = [Regions]
```

## Index

```@index
```

[^Ghali]:

    Sherif Ghali, Introduction to Geometric Computing, Springer 2008


