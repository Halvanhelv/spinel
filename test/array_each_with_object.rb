# Array#each_with_object on poly_array and ptr_array used to silently
# miss the type-check; the loop body never ran. Both shapes covered.

# poly_array (heterogeneous)
n = 0
[1, "x"].each_with_object("") {|_e, _a| n += 1 }
puts n

# ptr_array (user objects)
class Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

m = 0
[Bar.new(1), Bar.new(2)].each_with_object("") {|_e, _a| m += 1 }
puts m
