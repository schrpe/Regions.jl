using Regions, Images, FileIO

img = load(joinpath(@__DIR__, "..", "test", "gear.png"))

gear = binarize(img, px -> px < 0.9)

cx, cy = 256, 258          # gear centre (column, row), 1-based
hub_radius   = 60          # inner solid disk before teeth begin
outer_radius = 240         # outer boundary that encloses all gear material

hub          = region_from_circle(cx, cy, hub_radius)
teeth_only   = difference(gear, hub)
outline      = region_from_circle(cx, cy, outer_radius)
teeth_trimmed = intersection(teeth_only, outline)
hub_region   = intersection(gear, hub)

# Compose: darken the background image and draw region pixels bright white.
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

outdir = @__DIR__

save(joinpath(outdir, "src", "gear_full.png"),    overlay(img, gear))
save(joinpath(outdir, "src", "gear_teeth.png"),   overlay(img, teeth_trimmed))
save(joinpath(outdir, "src", "gear_hub.png"),     overlay(img, hub_region))

println("Done — saved gear_full.png, gear_teeth.png, gear_hub.png to docs/src/")
