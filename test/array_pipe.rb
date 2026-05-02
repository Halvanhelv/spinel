# Array#| dispatches to the typed-array union helpers.
# Element semantics are covered in test/array_union.rb.

# Each typed-array branch.
puts ([1, 2, 3] | [3, 4, 5]).inspect
puts (["a", "b"] | ["b", "c"]).inspect
puts ([1.0, 2.0] | [2.0, 3.0]).inspect
puts ([:a, :b] | [:b, :c]).inspect

# Variable receiver: literal operands take a different path.
a = [1, 2, 3]
puts (a | [3, 4]).inspect

# Chained: the left `|` must be inferred as int_array.
puts ([1, 2] | [2, 3] | [3, 4]).inspect
