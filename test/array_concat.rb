# Array#concat used to silently miss the type-check on both poly_array
# and ptr_array — the loop never ran, so the receiver kept its
# original length. Both shapes regression-tested here.

# poly_array (heterogeneous)
a = [1, "x"]
a.concat([2, "y"])
puts a.length

# ptr_array (user objects)
class Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

b = [Bar.new(1)]
b.concat([Bar.new(2), Bar.new(3)])
puts b.length
