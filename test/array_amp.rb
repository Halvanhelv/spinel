# Array#& dispatches to the typed-array intersect helpers.
# Element semantics are covered in test/array_intersection.rb;
# this test only exercises the operator dispatch path.

# Each typed-array branch.
puts ([1, 2, 3, 4] & [3, 4, 5]).inspect
puts (["a", "b", "c"] & ["b", "c"]).inspect
puts ([1.0, 2.0, 3.0] & [2.0, 3.0]).inspect
puts ([:a, :b, :c] & [:b, :c]).inspect

# Variable receiver: literal operands take a different path.
a = [1, 2, 3, 4]
puts (a & [3, 4, 5]).inspect

# Chained: the left `&` must be inferred as int_array.
puts ([1, 2, 3, 4] & [2, 3, 4] & [3, 4]).inspect
