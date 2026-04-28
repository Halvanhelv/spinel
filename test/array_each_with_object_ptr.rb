# Array#each_with_object on a ptr_array used to silently miss the
# type-check; the loop body never ran.

class Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

n = 0
[Bar.new(1), Bar.new(2)].each_with_object("") {|_e, _a| n += 1 }
puts n
