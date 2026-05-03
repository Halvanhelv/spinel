# When parent and child both record the same ivar name, the struct
# field is contributed once by `emit_parent_fields`. `emit_class_struct`
# already skips child-side redeclaration, so child's own gc_scan walk
# must also skip the inherited slot — otherwise it emits a second
# (often miscast) mark on top of the parent walk's correct mark.
#
# Here parent's `@data` is widened to poly (heterogeneous writes), and
# child also writes `@data` from a method-returned poly value, exercising
# the inherited-slot path under GC pressure.

class Base
  def initialize(kind)
    if kind == 0
      @data = [1, 2, 3]
    else
      @data = "hello"
    end
  end
end

class Holder
  def initialize(v)
    @v = v
  end
  attr_reader :v
end

class Child < Base
  def initialize(h)
    super(0)
    @data = h.v
  end
end

class Trash
  def initialize(n)
    @n = n
    @s = "padding payload " * 64
  end
end

h_str = Holder.new("from-holder")
Holder.new(123)
c = Child.new(h_str)

junk = []
i = 0
while i < 5000
  junk << Trash.new(i)
  i = i + 1
end

puts junk.length
puts "ok"
