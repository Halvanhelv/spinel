# Expression-form `obj.attr = rhs` on a poly slot used to lower to
# the comma expression `(slot = box(rhs), rhs)`, which evaluates rhs
# textually twice in C. If rhs has side effects (a method call, a
# string allocation, etc.) they run twice. Verify rhs runs exactly
# once by spilling to a typed temp via statement expression.

class Counter
  def initialize
    @n = 0
  end
  def step
    @n = @n + 1
    @n
  end
end

class Bag
  attr_accessor :item
  def initialize
    @item = "tag"   # widen slot to poly via heterogeneous writes
    @item = 5
  end
end

c = Counter.new
b = Bag.new
puts (b.item = c.step)   # 1  (chain value is rhs; step runs once)
puts (b.item = c.step)   # 2
puts (b.item = c.step)   # 3
