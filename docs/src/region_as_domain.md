```@meta
CurrentModule = Regions
DocTestSetup = quote
    using Regions
end
```

# Region as a Domain of Definition

Once a `Region` has been computed — by segmentation, by combining geometric primitives, or
by any of the morphological operations — it can be used as a *domain* for arbitrary image
operations. Statistics, point operations, and filters can be applied to only the pixels
inside the region, leaving the rest of the image untouched. Because the runs of a region
are stored column by column, iterating over them produces a memory-access pattern that is
cache-friendly under Julia's column-major storage.

## Iteration pattern

The natural iteration order over a region's pixels is *column first, row second*:

```julia
for run in region.runs
    for row in run.rows
        pixel = img[row, run.column]
        # ... use pixel ...
    end
end
```

Each inner loop reads a contiguous slice of one column of `img`, which lies in consecutive
memory under Julia's column-major layout. This is the same access pattern that
[`binarize`](@ref) uses on the way *into* a region — using a region as a domain keeps that
pattern on the way out.

## Statistics over a region

Computing the mean and standard deviation of pixel values inside a region is a one-pass
walk over the runs:

```julia
using Statistics

function region_mean_std(img, region)
    n = 0
    s = 0.0
    s2 = 0.0
    for run in region.runs
        for row in run.rows
            v = float(img[row, run.column])
            n  += 1
            s  += v
            s2 += v * v
        end
    end
    mean = s / n
    var  = s2 / n - mean * mean
    return (mean = mean, std = sqrt(var))
end
```

Cost is `O(n_pixels_in_region)` rather than `O(W · H)` — for sparse regions on large
images this is a substantial saving.

## Point operations restricted to a region

The same iteration pattern applies to in-place point operations. The example below
contrast-stretches only the pixels inside `region`, leaving the rest of `img` unchanged:

```julia
function stretch_inside!(img, region; lo = 0.2, hi = 0.8)
    for run in region.runs
        for row in run.rows
            v = float(img[row, run.column])
            v = clamp((v - lo) / (hi - lo), 0.0, 1.0)
            img[row, run.column] = v
        end
    end
    return img
end
```

## Combining with set operations

Because regions support `union`, `intersection`, `difference`, and `complement`, a domain
can be built up from segmentation and geometry without ever materialising a Bool mask:

```julia
foreground = binarize(img, px -> px < 0.5)        # segmented foreground
roi        = region_from_circle(cx, cy, r)         # circular ROI
domain     = intersection(foreground, roi)         # foreground inside the ROI

stats      = region_mean_std(img, domain)          # mean/std restricted to that domain
```

This is the core compositional advantage of representing the analysis domain as a region
rather than as a Bool array: ROI restriction, hole filling, dilation, and other refinements
all compose at run-list cost, not at `W · H` cost.
