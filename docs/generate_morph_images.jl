using Regions
using FileIO, Images

img  = load(joinpath(@__DIR__, "..", "test", "gear.png"))
gear = binarize(img, px -> px < 0.9)

se5  = region_from_circle(0, 0, 5)   # SE for erosion / dilation
se8  = region_from_circle(0, 0, 8)   # SE for opening / closing
se2  = region_from_circle(0, 0, 2)   # SE for gradient

eroded   = Regions.erosion(gear, se5)
dilated  = Regions.dilation(gear, se5)
opened   = Regions.opening(gear, se8)
closed   = Regions.closing(gear, se8)
grad     = Regions.morphological_gradient(gear, se2)
filled   = Regions.fill_holes(gear)

function overlay(base_gray, region; bg_scale=0.25)
    out = RGB.(base_gray .* bg_scale)
    for run in region.runs
        for row in run.rows
            if 1 <= row <= size(out, 1) && 1 <= run.column <= size(out, 2)
                out[row, run.column] = RGB(1, 1, 1)
            end
        end
    end
    return out
end

outdir = joinpath(@__DIR__, "src")
save(joinpath(outdir, "gear_eroded.png"),  overlay(img, eroded))
save(joinpath(outdir, "gear_dilated.png"), overlay(img, dilated))
save(joinpath(outdir, "gear_opened.png"),  overlay(img, opened))
save(joinpath(outdir, "gear_closed.png"),  overlay(img, closed))
save(joinpath(outdir, "gear_gradient.png"),overlay(img, grad))
save(joinpath(outdir, "gear_filled.png"),  overlay(img, filled))

println("Done.")
println("  eroded:  ", area(eroded),  " px (was ", area(gear), ")")
println("  dilated: ", area(dilated), " px")
println("  opened:  ", area(opened),  " px")
println("  closed:  ", area(closed),  " px")
println("  gradient:", area(grad),    " px")
println("  filled:  ", area(filled),  " px")
