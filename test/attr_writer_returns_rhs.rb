# `obj.attr = v` as an expression should evaluate to `v`, the rhs,
# matching Ruby semantics. Codegen used to emit `(rc->iv = v, 0)` —
# the trailing `, 0` made the C expression value `0`, so chained
# writes `local = obj.attr = v` saw 0 instead of v.

class Box
  attr_accessor :n
  def initialize
    @n = 0
  end
end

b = Box.new
local = (b.n = 42)
puts local      # 42
puts b.n        # 42

# Chained variant — both lvalues should land on the same rhs value.
b1 = Box.new
b2 = Box.new
b1.n = b2.n = 7
puts b1.n       # 7
puts b2.n       # 7
