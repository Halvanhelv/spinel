# Array#concat on a ptr_array used to silently miss the type-check; the
# loop never ran, so the receiver kept its original length.

class Bar
  def initialize(x); @x = x; end
  attr_accessor :x
end

a = [Bar.new(1)]
a.concat([Bar.new(2), Bar.new(3)])
puts a.length
