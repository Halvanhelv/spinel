# Array#flat_map where the block returns a ptr_array failed to type
# the result; the inferred receiver-array type clashed with the
# generated sp_PtrArray * inner accumulator.

class Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

a = [Bar.new(1), Bar.new(2)].flat_map { |b| [b, b] }
puts a.length
