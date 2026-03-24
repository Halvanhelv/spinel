class Temperature
  attr_reader :degrees
  def initialize(d)
    @degrees = d
  end
  def <=>(other)
    @degrees - other.degrees
  end
  def <(other); (self <=> other) < 0; end
  def >(other); (self <=> other) > 0; end
  def ==(other); (self <=> other) == 0; end
end

t1 = Temperature.new(100)
t2 = Temperature.new(200)
t3 = Temperature.new(100)
puts t1 < t2    # true
puts t2 > t1    # true
puts t1 == t3   # true
puts t1 > t2    # false
puts "done"
