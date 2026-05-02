# Issue #210 follow-up: an empty `map {}` block must still produce
# an array of the same length as the receiver. Each map dispatch
# (Range#, N.times#, int_array#, str_array#, poly_array#) used to
# skip the push entirely on an empty block, leaving the typed
# accumulator short and downstream `.length` / `[i]` wrong.

# Range#map
puts (0..2).map {}.length          # 3

# N.times.map
puts 4.times.map {}.length         # 4

# int_array#map
puts [10, 20, 30].map {}.length    # 3

# str_array#map
puts ["a", "b", "c", "d"].map {}.length   # 4

# poly_array#map
puts [1, "two", :three].map {}.length     # 3

# ptr_array#map (homogeneous obj_X[])
class Box
  def initialize(v); @v = v; end
end
puts [Box.new(1), Box.new(2), Box.new(3)].map {}.length  # 3
