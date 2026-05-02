# `compile_map_expr` had no `poly_array` recv branch — a
# heterogeneous-element array (`[1, "two", :three]`) called
# `.map { ... }` and the dispatch fell through to the `"0"`
# placeholder. The result was typed as `sp_IntArray *` (per the
# inferred map result), `lv_out = 0` was emitted, and any
# `.length` / `[i]` on the accumulator dereferenced NULL,
# crashing at runtime.

# (1) poly_array → IntArray (int-return block).
arr = [1, "two", :three, 4.5]
out = arr.map { |x| x.to_s.length }
puts out.length      # 4
puts out[0]          # 1
puts out[1]          # 3
puts out[2]          # 5
puts out[3]          # 3

# (2) poly_array → StrArray (string-return block).
strs = arr.map { |x| x.to_s }
puts strs.length     # 4
puts strs[0]         # 1
puts strs[1]         # two
puts strs[2]         # three
puts strs[3]         # 4.5

# (3) poly_array → IntArray (different int expression).
sizes = arr.map { |x| x.to_s.length * 2 }
puts sizes.length    # 4
puts sizes[0]        # 2
puts sizes[3]        # 6
