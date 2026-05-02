# Array#- dispatches to the typed-array difference helpers.
# Element semantics are covered in test/array_difference.rb.

# Each typed-array branch.
puts ([1, 2, 3, 4] - [2, 4]).inspect
puts (["a", "b", "c"] - ["b"]).inspect
puts ([1.0, 2.0, 3.0] - [2.0]).inspect
puts ([:a, :b, :c] - [:b]).inspect

# Variable receiver: literal operands take a different path.
a = [1, 2, 3, 4]
puts (a - [2, 4]).inspect

# Chained: the left `-` must be inferred as int_array.
puts ([1, 2, 3, 4, 5] - [2] - [4]).inspect
