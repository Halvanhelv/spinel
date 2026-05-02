# `[*0..n]` and `[*arr]` are array literals with a SplatNode element.
# Without SplatNode handling in compile_array_literal, the splat was
# lowered to a single default value (e.g., just the range's lower
# bound), so `[*0..4096]` produced a 1-element array. This broke
# optcarrot's dummy palette and made every `palette[i]` for i > 0
# read out-of-bounds garbage.

a = [*0..5]
puts a.length
puts a[0]
puts a[3]
puts a[5]

b = [*0...4]
puts b.length
puts b[0]
puts b[3]

src = [10, 20, 30]
c = [*src]
puts c.length
puts c[0]
puts c[2]
