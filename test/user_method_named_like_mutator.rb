# compile_body_return treats certain method names (`update`, `clear`,
# `concat`, `delete`, `each`, `pop`, `push`, `merge!`, ...) as
# statement-only because Hash and Array mutators are conventionally
# called for side-effect. That's right when the receiver IS a Hash
# or Array, but it silently throws away the value when a user class
# happens to define a method with one of those names — including the
# implicit `self.update(...)` form, since the receiver chain isn't
# even consulted before the name match fires.
#
# Pre-fix, `C.new.f(7)` returned 0 (correct: 8) and
# `D.new.run(C.new)` returned 0 (correct: 30). Both follow Ruby
# semantics now.

class C
  def update(target)
    target
  end
  def f(n)
    update(n + 1)   # implicit self.update — was discarded
  end
end

class D
  def run(c)
    c.update(30)    # explicit recv on user class — was discarded
  end
end

puts C.new.f(7)
puts D.new.run(C.new)
