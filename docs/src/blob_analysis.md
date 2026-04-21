```@meta
CurrentModule = Regions
DocTestSetup = quote
    using Regions
end
```

# Blob Analysis

Blob analysis (connected-component analysis) takes a binary region and breaks it into
individual objects, then measures shape properties of each. The typical pipeline is:

1. **Segment** the image into a binary region (`binarize`).
2. **Split** the region into connected blobs (`components`).
3. **Measure** each blob with feature functions (`area`, `centroid`, `equivalent_ellipse`, …).

## Connected Components

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

## Basic Shape Features

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

## Centroid and Equivalent Ellipse

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

## Perimeter and Compactness

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

## Convex Hull and Shape Convexity

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

## Feret Diameters

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

## Hole Features

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

## Gear Analysis Example

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
