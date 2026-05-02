```@meta
CurrentModule = Regions
```

# Comparison with Related Packages

Regions.jl is one of several Julia packages for binary image analysis and component
labelling. This page summarises how it compares to the most common alternatives, where the
results agree, where they differ, and which package is the better fit for which task.

## Regions.jl vs. ImageMorphology.jl

[ImageMorphology.jl](https://github.com/JuliaImages/ImageMorphology.jl) is the standard
JuliaImages package for binary and grayscale morphology. It operates on dense arrays
(`BitMatrix`, `Array{Bool}`, grayscale arrays); Regions.jl operates on sparse run-length
encoded regions. The contrast is summarised in the table below.

| Aspect | Regions.jl | ImageMorphology.jl |
|---|---|---|
| Input representation | `Region` (run-length encoded) | `BitMatrix` / `Array{Bool}` / grayscale array |
| Structuring element | any `Region` | `strel_box`, `strel_diamond`, `OffsetArray{Bool}` |
| Memory | `O(n_runs)` | `O(W · H)` |
| Time per operation | `O(n_runs · n_se)` | `O(W · H · |SE|)` |
| Complement support | native via the `complement` flag | manual (`.!img`) |
| Image bounds | unbounded coordinate space | fixed image size; padding via `Pad` |
| Grayscale morphology | not provided | provided |

### Name collisions

Both packages export the names `opening` and `closing` (and `ImageMorphology` also exports
`erode`/`dilate` rather than `erosion`/`dilation`). When both are loaded with `using`,
Julia raises an ambiguity warning on `opening` and `closing`. Disambiguate with the module
prefix:

```julia
using Regions, ImageMorphology

result_regions = Regions.opening(reg, se)            # operate on a Region
result_image   = ImageMorphology.opening(bool_img)    # operate on a BitMatrix
```

`erosion`/`dilation` are unique to Regions.jl, so they don't collide.

### Equivalence of results

For a region produced by `binarize(img, predicate)`, applying matching morphological
operations in both packages produces **bit-identical results in the interior** of the
image. The two packages differ only at the image boundary, because they handle "outside the
image" differently:

- **ImageMorphology.jl** uses `Pad(:replicate)` by default — pixels outside the image are
  assumed to repeat the edge pixel.
- **Regions.jl** treats the coordinate space as infinite and unbounded — pixels outside
  any region are simply background.

Concretely, an erosion in Regions.jl removes the first and last row and column of an object
that touches the image boundary, whereas the same erosion in ImageMorphology.jl preserves
those edge pixels because the replicated padding pretends the object continues outside.

To reconcile the two:

- **Match Regions semantics from ImageMorphology**: pass `Fill(false)` padding to the
  ImageMorphology call, so out-of-image pixels are treated as background.
- **Match ImageMorphology semantics from Regions**: intersect with an inner box, e.g.
  `intersection(eroded, region_from_box(2, 2, W-1, H-1))`, so edge pixels are excluded.

### When to use which

- **Reach for ImageMorphology.jl** when you already have a `BitMatrix` or `Array{Bool}` and
  want to stay in that representation, or when you need grayscale morphology
  (`mreconstruct`, top-hat, etc.).
- **Reach for Regions.jl** when morphology is one step in a longer pipeline (binarization
  → set operations → component decomposition → measurements), when the objects are sparse
  relative to the image area, when structuring elements are large, or when real-time
  performance matters. The one-time cost of `binarize` is amortised after a few operations,
  and from there the speedup over pixel-array morphology grows with the
  `n_runs : W · H` ratio: typically 5–30× on dense images and 50–1000× on sparse
  industrial images. Larger structuring elements widen the gap further, because RLE cost
  scales with run count rather than SE pixel count.

## Regions.jl vs. ImageSegmentation.jl and ImageComponentAnalysis.jl

[ImageSegmentation.jl](https://github.com/JuliaImages/ImageSegmentation.jl) provides
segmentation algorithms (Watershed, Felzenszwalb, region-growing, …) that produce a label
array. [ImageComponentAnalysis.jl](https://github.com/JuliaImages/ImageComponentAnalysis.jl)
takes a label array and computes shape properties (area, perimeter, eccentricity, …).
Regions.jl covers the same ground for the predicate-segmentation case, in a single
representation:

| Feature | Regions.jl | ImageSegmentation.jl | ImageComponentAnalysis.jl |
|---|---|---|---|
| Representation | column-major RLE | pixel label array | pixel label array |
| Memory | `O(n_runs)` | `O(W · H)` | `O(W · H)` |
| Morphology | `O(n_runs · n_se)` | `O(W · H · |SE|)` | — |
| Set operations | `union`, `intersection`, `difference`, `complement` | — | — |
| Complement / infinite regions | yes (`complement` flag, De Morgan) | no | no |
| Region as domain for image ops | yes | no | no |
| Parallelisation | column-wise, kicks in for ≥ 1024 columns | — | — |
| Segmentation algorithms | predicate-based `binarize` | Watershed, Felzenszwalb, region-growing, … | — |
| Shape measurements | area, perimeter, centroid, equivalent ellipse, Feret, holes, convex hull, … | — | area, perimeter, eccentricity, … |

### When to use which

- **ImageSegmentation.jl** when you need a richer segmentation algorithm than a per-pixel
  predicate — e.g. watershed for touching objects, graph-based segmentation for textured
  scenes.
- **ImageComponentAnalysis.jl** when you already have a label array (from
  ImageSegmentation.jl or elsewhere) and need shape features computed in that representation.
- **Regions.jl** when your segmentation reduces to a pixel-level predicate, when you want
  fast morphology and set operations on the segmented result, when you intend to use the
  segmentation as a domain for selective image processing, or when you need real-time
  industrial-vision performance on sparse scenes.
