# Chained `@a = @b = ... = literal` where the targets have different
# concrete slot types (here: a string ivar and an int ivar). Without
# splitting the chain into per-target writes, the outer assignment's
# RHS picks up the inner ivar's recorded type, and the C compiler
# rejects the cross-typed slot store.

class C
  def initialize
    @a = "hello"
    @b = 42
  end

  def reset
    @a = @b = nil
  end

  def show
    puts @a
    puts @b
  end
end

c = C.new
c.show
c.reset
puts "reset ok"
