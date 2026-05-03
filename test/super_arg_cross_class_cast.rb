# Two subclasses each call `super` from `initialize` forwarding a
# differently-typed arg. The parent's param-type inference picks one
# concrete C type, so the other subclass's super-forwarded arg ends
# up with a mismatching C type at the call site without an explicit
# cast.

class Box
  def initialize(v)
    @v = v
  end
end

class StrBox < Box
  def initialize(s)
    super
    @len = s.length
  end

  def len
    @len
  end
end

class IntBox < Box
  def initialize(n)
    super
    @doubled = n * 2
  end

  def doubled
    @doubled
  end
end

s = StrBox.new("hello")
puts s.len

n = IntBox.new(7)
puts n.doubled
