# Array#+ used to fall through on poly_array / ptr_array — the result
# temp held its default 0 because the dispatcher's type-list omitted
# those shapes.

# poly_array
a = [1, "x"]
b = [2, "y"]
puts (a + b).length

# ptr_array
class Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

c = [Bar.new(1)]
d = [Bar.new(2)]
puts (c + d).length
