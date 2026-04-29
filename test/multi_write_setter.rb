# `a, b, c.x = expr` where one target is a setter call (`c.x =`)
# parses to a CallTargetNode in the targets list. Without parser
# support for CallTargetNode the setter target was silently dropped.

class Box
  def initialize; @v = 0; end
  attr_accessor :v
end

class Holder
  def initialize
    @a = 0
    @b = 0
    @c = Box.new
  end
  def fill
    @a, @b, @c.v = [11, 22, 33]
  end
  def show
    puts @a
    puts @b
    puts @c.v
  end
end

h = Holder.new
h.fill
h.show
