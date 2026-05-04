# Array#flat_map where the block returns a poly_array / ptr_array
# failed to type the result; the inferred receiver-array type clashed
# with the generated inner accumulator. Both shapes covered.

# poly_array
a = [1, "x"].flat_map { |pe| [pe, pe] }
puts a.length

# ptr_array
class Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

b = [Bar.new(1), Bar.new(2)].flat_map { |re| [re, re] }
puts b.length
