# Deep-nested array literals (3D and beyond). Spinel doesn't
# have a typed `<X>_ptr_array_ptr_array` slot — the second-level
# `[[1,2,3],[4,5,6]]` infers as `int_array_ptr_array` and the
# outer `[[[...]],[[...]]]` would naively box each element via
# `sp_box_ptr_array`, which erases the elem-type info and
# leaves the dispatch returning an unknown obj at the next `[]`
# read.
#
# Fix: when an array literal element is itself a typed
# ptr_array (or already poly_array) and the outer is
# poly_array, recompile the inner literal as poly_array so
# every level boxes via `sp_box_poly_array` / `sp_box_int_array`
# / etc. — the cls_id chain stays tagged and the poly-builtin
# dispatch recurses correctly through `arr[i][j][k]...`.
#
# The recursion in `compile_array_literal_as_poly` makes the
# fix dimension-agnostic — 3D, 4D, 5D, ... all work.
#
# Without the fix `read` returned 0 for every index (sp_box_nil
# fallback). With the fix it returns the right ints.

class H3
  def initialize
    @t = [[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [10, 11, 12]]]
  end
  def read(i, j, k); @t[i][j][k]; end
end

h3 = H3.new
puts h3.read(0, 0, 0)   # 1
puts h3.read(0, 1, 1)   # 5
puts h3.read(1, 0, 2)   # 9
puts h3.read(1, 1, 2)   # 12

# 4D — recursion handles arbitrary depth.
class H4
  def initialize
    @t = [[[[1, 2], [3, 4]], [[5, 6], [7, 8]]],
          [[[9, 10], [11, 12]], [[13, 14], [15, 16]]]]
  end
  def read(i, j, k, l); @t[i][j][k][l]; end
end

h4 = H4.new
puts h4.read(0, 0, 0, 0)   # 1
puts h4.read(0, 1, 0, 1)   # 6
puts h4.read(1, 0, 1, 0)   # 11
puts h4.read(1, 1, 1, 1)   # 16
