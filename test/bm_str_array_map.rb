# Array#map on a str_array. Issue #43: compile_map_expr had no
# str_array branch, so `tt = foo.map { |s| ... }` silently emitted
# `lv_tt = 0` and the subsequent iteration crashed.

# String -> string map (the original failure mode)
foo = ["a", "b", "c"]
tt = foo.map { |s| s.upcase }
tt.each { |t| puts t }   # A B C

# String -> int map: codepoint length, returning int_array
sizes = foo.map { |s| s.length }
puts sizes.length         # 3
puts sizes[0]             # 1
puts sizes[1]             # 1
puts sizes[2]             # 1

# Original receiver is unchanged
puts foo[0]               # a
puts foo[1]               # b
puts foo[2]               # c

# .map { ... }.each { ... } chain (the issue's pattern)
words = ["alpha", "beta", "gamma"]
words.map { |w| w.upcase }.each { |w| puts w }   # ALPHA BETA GAMMA

# Empty input
empty = "".split(",")
e2 = empty.map { |s| s.upcase }
puts e2.length            # 0
