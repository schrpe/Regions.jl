using Regions, Images, FileIO

img = load(joinpath(@__DIR__, "..", "test", "gear.png"))

region = binarize(img, px -> px < 0.9)
blob   = argmax(area, components(region))

l, t, r, b = bounds(blob)
cc, cr     = centroid(blob)

@info "bounds"   left=l top=t right=r bottom=b
@info "centroid" col=cc row=cr

out = RGB.(img .* 0.4)
for run in blob.runs, row in run.rows
    out[row, run.column] = RGB(1, 1, 1)
end

out[t,   l:r] .= RGB(0, 1, 0)
out[b,   l:r] .= RGB(0, 1, 0)
out[t:b, l]   .= RGB(0, 1, 0)
out[t:b, r]   .= RGB(0, 1, 0)

ci, ri = round.(Int, (cc, cr))
H, W = size(out)
for d in -4:4
    out[clamp(ri,     1, H), clamp(ci + d, 1, W)] = RGB(1, 0, 0)
    out[clamp(ri + d, 1, H), clamp(ci,     1, W)] = RGB(1, 0, 0)
end

save(joinpath(@__DIR__, "src", "gear_example.png"), out)
println("Done — saved gear_example.png to docs/src/")
