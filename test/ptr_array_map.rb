# `compile_map_expr` had no `ptr_array` recv branch — `.map { ... }`
# on a typed `obj_X[]` ivar/local fell through to the trailing
# `"0"` placeholder. The map's result type was inferred as e.g.
# `int_array`, spinel emitted `lv_out = 0`, and any `.length` /
# `[i]` on the typed accumulator dereferenced NULL — runtime
# SIGSEGV.
#
# Mirrors `test/poly_array_map.rb` for the homogeneous obj_X case.

class Box
  attr_reader :v
  def initialize(v); @v = v; end
end

class Bag
  def initialize
    @items = [Box.new(1), Box.new(2), Box.new(3)]
  end
  def doubled
    @items.map { |b| b.v * 2 }
  end
  def names
    @items.map { |b| "v=#{b.v}" }
  end
end

bag = Bag.new

# ptr_array → IntArray (int-return block).
ints = bag.doubled
puts ints.length     # 3
puts ints[0]         # 2
puts ints[2]         # 6

# ptr_array → StrArray (string-return block).
names = bag.names
puts names.length    # 3
puts names[0]        # v=1
puts names[2]        # v=3
