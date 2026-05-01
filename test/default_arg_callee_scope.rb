# When a callee method's default-arg expression reads from an
# instance variable OR calls a same-class method without an
# explicit receiver, the inlined expansion at the caller's site
# must resolve against the call's *receiver* (and the callee's
# class), not the caller's `self`. Naive inlining either fails to
# compile or routes through the wrong vtable.

# (1) Default reads `@ivar` — must resolve against the recv's
# instance, not the caller's.
class Wrapper
  def initialize(seed)
    @base = seed
  end
  def grab(target = @base * 10)
    target
  end
end

class Caller
  def initialize
    @w = Wrapper.new(3)
  end
  def go
    @w.grab        # default `@base * 10` → 3 * 10 = 30
  end
end

puts Caller.new.go      # 30

# (2) Default calls a same-class bare method — must dispatch to
# the *callee's* class, not the caller's. Caller defines its own
# method by the same name, but Foo's default should still call
# Foo's version.
class Foo
  def target
    1
  end
  def foo(opt = target)
    opt
  end
end

class Bar
  def target
    2          # different value — must NOT be picked up
  end
  def check
    Foo.new.foo
  end
end

puts Bar.new.check       # 1 (Foo#target, not Bar#target)
