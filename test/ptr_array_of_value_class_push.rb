# Issue #91 (follow-up to PR #87): PR #87 excluded value-type-eligible
# classes from the value-type optimization when their instances appear
# in an `[Foo.new(...)]` literal. The same root mismatch fired through
# the push-promotion path — `arr = []; arr.push(Foo.new(...))` — where
# no literal exists at scan time, so the literal-walk in
# `detect_ptr_array_stored_types` missed it and Foo got optimized
# into a value type. The push call then tried to feed a struct-by-
# value into `sp_PtrArray_push`'s `void *` arg.
#
# Fix walks every push-style CallNode (`push`, `<<`, `unshift`,
# `prepend`) and adds `obj_<C>` to the exclusion list whenever the
# argument has that type.

class Foo
  def initialize(x); @x = x; end
  attr_reader :x
end

# `push` form — the issue's exact reproducer.
arr = []
arr.push(Foo.new(1))
arr.push(Foo.new(2))
puts arr.length
arr.each { |f| puts f.x }
# 2 / 1 / 2

# `<<` form — same code path through the parser.
arr2 = []
arr2 << Foo.new(10)
arr2 << Foo.new(20)
arr2 << Foo.new(30)
puts arr2.length
arr2.each { |f| puts f.x }
# 3 / 10 / 20 / 30
