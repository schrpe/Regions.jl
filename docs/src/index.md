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

## Morphological Operations

Morphological operations transform a region using a second region called a **structuring
element** (SE). The SE acts as a probe that is slid across every pixel; its shape and size
set the spatial scale at which features are grown, shrunk, or detected.

**Structuring elements must be centred on the origin.** Two common choices:

| SE | Construction | Character |
|----|-------------|-----------|
| Disk | `region_from_circle(0, 0, r)` | Isotropic — treats all directions equally |
| Square | `region_from_box(-r, r, r, -r)` | Axis-aligned — sharper corners, faster |

### Erosion

`erosion(a, se)` shrinks `a`. A pixel is kept only when the SE, placed at that pixel, fits
entirely inside `a`. Protrusions narrower than the SE are trimmed away.

```jldoctest reg
julia> region5 = region_from_box(-3, 3, 3, -3);  # 7×7 = 49 pixels

julia> se_sq   = region_from_box(-1, 1, 1, -1);  # 3×3 square SE

julia> e = erosion(region5, se_sq);

julia> area(e)                                    # shrinks to 5×5
25

julia> contains(e, -2, 0)                        # 1 pixel inside the original boundary
true

julia> contains(e, -3, 0)                        # original boundary pixel — removed
false
```

A disk SE erodes isotropically. `erosion(region_from_circle(0,0,r), region_from_circle(0,0,s))`
gives `region_from_circle(0,0,r-s)` when `r > s`.

### Dilation

`dilation(a, se)` grows `a`. A pixel is added for every pixel of the SE placed at every
pixel of `a` — equivalently, every point reachable by sliding the SE over the region.

```jldoctest reg
julia> small = region_from_box(-1, 1, 1, -1);   # 3×3

julia> d = dilation(small, se_sq);              # 3×3 dilated by 3×3

julia> area(d)                                  # grows to 5×5
25

julia> contains(d, 2, 0)                        # pixel added beyond original boundary
true
```

Dilation is the dual of erosion: `dilation(a, se) == invert(erosion(invert(a), se))`.

### Opening

`opening(a, se)` = erosion followed by dilation with the same SE. It removes foreground
features (isolated pixels, thin protrusions) smaller than the SE while leaving larger
structures nearly unchanged. The result is always a **subset** of `a`.

```jldoctest reg
julia> opening(region5, se_sq) == region5       # box survives — no features smaller than SE
true

julia> isempty(opening(Region([Run(0, 0:0)]), se_sq))  # isolated pixel is removed
true
```

Opening is idempotent: applying it twice gives the same result as applying it once.

### Closing

`closing(a, se)` = dilation followed by erosion. It fills background features (narrow gaps,
small holes) smaller than the SE while leaving the overall shape nearly unchanged. The result
always **contains** `a` as a subset.

```jldoctest reg
julia> gapped = union(region_from_box(-3, 3, -1, -3),   # two bars with a 1-column gap
                      region_from_box( 1, 3,  3, -3));

julia> area(gapped)                                      # 6 columns × 7 rows, gap missing
42

julia> c3 = closing(gapped, se_sq);

julia> contains(c3, 0, 0)                               # gap at column 0 is filled
true

julia> area(c3)                                         # gap plus rounded corners added
49
```

### Morphological Gradient

`morphological_gradient(a, se)` = `difference(dilation(a,se), erosion(a,se))`. The result
is a ring that straddles the boundary of `a`, extending one SE radius both inside and outside.

```jldoctest reg
julia> grad = morphological_gradient(region5, se_sq);

julia> area(grad)                                       # 9×9 minus 5×5
56

julia> contains(grad, -3, 0)                           # boundary pixel — in the ring
true

julia> contains(grad, 0, 0)                            # interior pixel — not in the ring
false
```

### Inner and Outer Boundary

`inner_boundary` and `outer_boundary` use a fixed 3×3 square SE and split the gradient into
the layer that lies *inside* versus *outside* the region.

```jldoctest reg
julia> ib = inner_boundary(region5);

julia> area(ib)                                        # one pixel ring inside
24

julia> contains(ib, -3, 0)                            # outermost layer of region5
true

julia> contains(ib, -2, 0)                            # second layer — not inner boundary
false

julia> ob = outer_boundary(region5);

julia> area(ob)                                        # one pixel ring outside
32

julia> contains(ob, -4, 0)                            # first pixel beyond boundary
true

julia> contains(ob, -3, 0)                            # the boundary itself — not outer boundary
false
```

### Holes and fill\_holes

`holes(a)` returns all enclosed background regions — connected components of the background
inside the bounding box that do not touch any edge. `fill_holes(a)` fills them all.

```jldoctest reg
julia> box_frame = difference(region_from_box(-3, 3, 3, -3),
                              region_from_box(-1, 1, 1, -1));  # 7×7 box with 3×3 hole

julia> hs = holes(box_frame);

julia> length(hs)                                         # one enclosed hole
1

julia> contains(hs[1], 0, 0)                             # the hole contains the origin
true

julia> filled_box = fill_holes(box_frame);

julia> area(filled_box)                                   # hole filled — back to 7×7
49

julia> contains(filled_box, 0, 0) && contains(filled_box, -3, 0)
true
```

### Gear Example

Applying morphological operations to the segmented gear illustrates each operation's effect
at the scale of the gear teeth (radius-5 disk SE for erosion/dilation, radius-8 for
opening/closing):

```julia
se5 = region_from_circle(0, 0, 5)    # disk SE, radius 5
se8 = region_from_circle(0, 0, 8)    # disk SE, radius 8
se2 = region_from_circle(0, 0, 2)    # disk SE, radius 2

eroded  = erosion(gear, se5)          # teeth shaved inward by 5 px
dilated = dilation(gear, se5)         # teeth grown outward by 5 px
opened  = opening(gear, se8)          # small protrusions removed
closed  = closing(gear, se8)          # narrow inter-tooth gaps bridged
grad    = morphological_gradient(gear, se2)   # boundary ring
filled  = fill_holes(gear)            # spoke voids and shaft hole filled
```

| Original | Eroded (r = 5) | Dilated (r = 5) |
|:--------:|:--------------:|:---------------:|
| ![Original gear](gear_full.png) | ![Eroded gear](gear_eroded.png) | ![Dilated gear](gear_dilated.png) |

| Opened (r = 8) | Closed (r = 8) | Gradient (r = 2) |
|:--------------:|:--------------:|:----------------:|
| ![Opened gear](gear_opened.png) | ![Closed gear](gear_closed.png) | ![Morphological gradient](gear_gradient.png) |

| Holes filled |
|:-----------:|
| ![Holes filled](gear_filled.png) |

The gradient image traces every edge in the gear — outer teeth profile, spoke edges, and
the shaft hole — as a thin white ring on the darkened original. The filled image shows the
gear outline with all interior voids removed: only the teeth profile remains.

## Blob Analysis

Blob analysis (connected-component analysis) takes a binary region and breaks it into
individual objects, then measures shape properties of each. The typical pipeline is:

1. **Segment** the image into a binary region (`binarize`).
2. **Split** the region into connected blobs (`components`).
3. **Measure** each blob with feature functions (`area`, `centroid`, `equivalent_ellipse`, …).

### Connected Components

`components(region, dx, dy)` returns a `Vector{Region}` — one element per connected blob.
Two runs are considered part of the same blob when their column distance is at most `dx`
and their row gap is at most `dy`. The defaults `dx = dy = 1` implement standard
8-connected labelling; larger values bridge small gaps between nearby objects.

```jldoctest reg
julia> b1 = region_from_circle(-20, 0, 5);

julia> b2 = region_from_circle(0, 0, 5);

julia> b3 = region_from_circle(20, 0, 5);

julia> three_blobs = union(union(b1, b2), b3);

julia> comps = components(three_blobs);

julia> length(comps)                              # three separated circles
3

julia> all(c -> area(c) == 81, comps)             # all three circles have equal area
true
```

The `dx` parameter bridges horizontal gaps. Two boxes separated by a 3-column gap are
two separate blobs at the default `dx = 1`, but merge into one when `dx = 4`:

```jldoctest reg
julia> box_a = region_from_box(0, 5, 3, 0);      # columns 0–3, rows 0–5

julia> box_b = region_from_box(7, 5, 10, 0);     # columns 7–10, rows 0–5

julia> two_boxes = union(box_a, box_b);

julia> length(components(two_boxes))              # gap of 3 columns exceeds dx=1
2

julia> length(components(two_boxes, unsigned(4), unsigned(0)))   # dx=4 bridges the gap
1
```

### Basic Shape Features

Each connected component is a `Region`, so all feature functions apply directly.

`area` returns the pixel count. `width` and `height` return the column and row extent of
the bounding box. `bounds_center` returns the midpoint of the bounding box as
`(column, row)`. `aspect_ratio` returns `width / height`.

```jldoctest reg
julia> blob = region_from_box(0, 1, 9, 0);       # 10-wide × 2-tall rectangle

julia> area(blob)
20

julia> width(blob)
10

julia> height(blob)
2

julia> bounds_center(blob)
(4.5, 0.5)

julia> aspect_ratio(blob)
5.0
```

### Centroid and Equivalent Ellipse

`centroid(r)` returns the area-weighted centre `(column, row)`. Unlike `bounds_center` it
is pulled toward dense parts of the region, not just the bounding-box midpoint.

`equivalent_ellipse(r)` fits the ellipse that has the same area, centroid, and
second-order moments as the region. It returns a named tuple
`(center, semi_axes, angle)` where `semi_axes = (major, minor)` and `angle` is in
radians from the column axis toward the row axis. The equivalent ellipse is useful for
estimating the orientation and elongation of a blob.

```jldoctest reg
julia> elong_box = region_from_box(0, 1, 9, -1);   # 10-wide × 3-tall, centred at row 0

julia> centroid(elong_box)
(4.5, 0.0)

julia> el = equivalent_ellipse(elong_box);

julia> el.center
(4.5, 0.0)

julia> round(el.semi_axes[1]; digits=4)             # major (horizontal) half-axis
5.7446

julia> round(el.angle; digits=4)                    # 0 — aligned with column axis
0.0
```

### Perimeter and Compactness

`perimeter(r)` counts exposed 4-connected boundary edges (each edge has length 1).
`compactness(r)` normalises the perimeter by the area using the isoperimetric ratio
`P² / (4π·A)`, which equals 1 for a perfect circle and grows for more irregular or
elongated shapes.

```jldoctest reg
julia> c5 = region_from_circle(0, 0, 5);

julia> perimeter(c5)
44.0

julia> round(compactness(c5); digits=4)             # close to 1 — nearly circular
1.902

julia> round(compactness(region_from_box(-2, 2, 2, -2)); digits=4)  # 5×5 square
1.2732
```

### Convex Hull and Shape Convexity

`convex_hull(r)` returns the convex hull of the region as an ordered list of
half-integer pixel-corner vertices. `convex_area` and `convex_perimeter` measure its
area and perimeter. `convexity` returns `area / convex_area` (1 for convex shapes,
< 1 when the shape has concavities). `perforation` returns the complementary fraction
`(convex_area − area) / convex_area`.

```jldoctest reg
julia> cross = Region([Run(-2, 0:0), Run(-1, 0:0), Run(0, -2:2), Run(1, 0:0), Run(2, 0:0)]);

julia> area(cross)
9

julia> convex_area(cross)
17.0

julia> round(convexity(cross); digits=4)            # 9/17 — arms create deep concavities
0.5294

julia> round(perforation(cross); digits=4)          # 47% of convex hull not filled by region
0.4706
```

### Feret Diameters

`feret_diameters(r)` returns `(min_feret, max_feret)` — the minimum and maximum caliper
widths obtained by rotating calipers on the convex hull. The minimum Feret diameter is
the narrowest gap a physical caliper could pass through. The maximum Feret diameter is
the longest diagonal of the convex hull.

```jldoctest reg
julia> blob_wide = region_from_box(0, 1, 9, 0);    # 10-wide × 2-tall

julia> mn_f, mx_f = feret_diameters(blob_wide);

julia> mn_f                                         # 2 px — fits through the short dimension
2.0

julia> round(mx_f; digits=3)                        # corner-to-corner diagonal
10.198
```

### Hole Features

`number_of_holes(r)` counts enclosed background components (the same regions that
`holes(r)` returns). `area_of_holes(r)` sums their pixel areas. Both are zero for
simply-connected (hole-free) regions.

```jldoctest reg
julia> blob_frame = difference(region_from_box(-3, 3, 3, -3),
                               region_from_box(-1, 1, 1, -1));  # 7×7 frame with 3×3 hole

julia> number_of_holes(blob_frame)
1

julia> area_of_holes(blob_frame)
9
```

### Gear Analysis Example

The gear is one connected region (`components` returns a single element) with a rich
toothed boundary. Strong erosion with a large disk SE shrinks every tooth to an isolated
stub and separates the stubs. Filtering by minimum area removes erosion artefacts; the
remaining blobs are the individual teeth. Shape features then characterise each tooth:

```julia
img  = load("test/gear.png")
gear = binarize(img, px -> px < 0.9)

println("area:       ", area(gear))             # 100431
println("holes:      ", number_of_holes(gear))  # 9 — spokes + shaft bore
println("hole area:  ", area_of_holes(gear))    # 58110 — enclosed voids
println("convexity:  ", round(convexity(gear); digits=3))  # 0.562 — teeth cut deep concavities
println("feret:      ", round.(feret_diameters(gear); digits=1))  # (473.1, 481.0) — outer diameter

se18        = region_from_circle(0, 0, 18)
eroded18    = erosion(gear, se18)               # shrink until teeth disconnect
tooth_comps = components(eroded18)
teeth       = filter(c -> area(c) >= 200, tooth_comps)  # drop sub-pixel artefacts
println("teeth:      ", length(teeth))          # 7 teeth visible in the image quadrant

for t in sort(teeth, by=area, rev=true)
    cen = centroid(t)
    el  = equivalent_ellipse(t)
    println("  area=$(area(t))  centroid=($(round(Int,cen[1])), $(round(Int,cen[2])))",
            "  major=$(round(el.semi_axes[1]; digits=1))")
end
```

The `convexity` of 0.56 quantifies what is visible in the image: only about 56% of the
gear's convex hull is actually filled, with the remainder being the inter-tooth concavities.
The 9 holes — 4 spoke cavities and the central shaft bore — account for more than half
the gear's own pixel area (58 110 out of 100 431 pixels).

## Reference

```@autodocs
Modules = [Regions]
```

## Index

```@index
```




