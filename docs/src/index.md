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
Pages = ["introduction.md", "set_operations.md", "morphology.md", "blob_analysis.md", "region_as_domain.md", "comparison.md", "reference.md"]
Depth = 2
```
