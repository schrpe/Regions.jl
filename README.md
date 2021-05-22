# Regions

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://schrpe.github.io/Regions.jl/dev)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

Regions.jl defines a set of types and functions that model a discrete 2-dimensional region concept.

Regions can be used for various purposes in machine vision and image processing. Since they provide an efficient run-length encoding of binary images, they avoid the need to touch every pixel when doing binary morphology and thus enable substantial speedup of such operations. Regions are also the basis for binary blob analysis, where the calculation of shape-based features is substantially accelerated because of the run-length encoding. Finally, regions can be used as the domain of image processing functions.

![Examples of regions](regions.png)

Examples of regions: two simple regions, a region with a hole and a region consisting of two parts.
