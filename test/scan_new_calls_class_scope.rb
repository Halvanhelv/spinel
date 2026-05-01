# `scan_new_calls` walks the AST looking for `Foo.new(args)` and
# propagates each arg's inferred type into Foo's initialize param-
# type table. The arg inference uses `infer_type`, which for an
# `InstanceVariableReadNode` consults `@current_class_idx` —
# previously the scan never set it.
#
# Result: `Bar.new(@x, ...)` inside `Foo#initialize` resolved
# `@x` against an empty scope (returned the int default), so
# Bar.initialize's first param wedged at mrb_int. The fix pins
# `@current_class_idx` while recursing into ClassNode bodies.

class A
  attr_reader :n
  def initialize(n)
    @n = n
  end
end

class B
  attr_reader :a
  def initialize(a_arg)
    @a = a_arg
  end
end

class C
  attr_reader :b
  def initialize
    @inner = A.new(7)
    @b = B.new(@inner)
  end
end

c = C.new
puts c.b.a.n   # 7
