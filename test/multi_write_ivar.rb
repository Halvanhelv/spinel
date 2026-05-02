# `@a, @b = expr1, expr2` (multi-write to ivars) was not picked up by
# `scan_ivars`, so the ivars were never registered and the struct
# came out missing them. The emit-time path in compile_stmt already
# handled InstanceVariableTargetNode; the gap was only in the
# collection pass.

class Inner
  def initialize(x); @x = x; end
  attr_reader :x
end

class HasObjects
  def initialize
    @left, @right = Inner.new(7), Inner.new(8)
  end
  def sum
    @left.x + @right.x
  end
end

class Holder
  def initialize
    @a, @b = 1, 2
  end
  attr_reader :a, :b
  def has_obj
    HasObjects.new.sum
  end
end

h = Holder.new
puts h.a
puts h.b
puts h.has_obj
