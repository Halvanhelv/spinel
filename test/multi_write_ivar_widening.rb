class Pair
  def initialize(a, b)
    @x, @y = [a, b]
  end
  attr_reader :x, :y
end

p = Pair.new("hello", "world")
puts p.x
puts p.y
