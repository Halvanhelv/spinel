# A value-type constructor body that introduces a GC-managed local
# (here `arr`, an int_array) needs `SP_GC_SAVE()` paired with the
# `SP_GC_ROOT(lv_arr)` that `declare_method_locals` emits.
#
# `emit_constructor` only emits SP_GC_SAVE for the non-value-type
# branch. For value types it leaves `@in_gc_scope` whatever the
# *previous* method left it as. If the previous method was a
# non-value class's body (which sets `@in_gc_scope = 1`), the
# inherited scope made `declare_method_locals` skip its SP_GC_SAVE
# and the value-type ctor emitted an unbalanced SP_GC_ROOT —
# pushing a stack pointer that becomes dangling on return.
#
# Reproducer: Foo (heap class) is compiled before Vec (value type),
# so without the fix Vec_new's lv_arr root gets pushed without a
# matching save. The fix resets `@in_gc_scope = 0` at the value-
# type ctor entry so declare_method_locals emits SP_GC_SAVE.

class Foo
  def make
    [1, 2, 3]
  end
end

class Vec
  attr_reader :sum
  def initialize(x, y)
    arr = [x, y, x + y]
    @sum = arr[2]
  end
end

f = Foo.new
puts f.make.length            # 3
v = Vec.new(3, 4)
puts v.sum                    # 7

# Many ctor calls so the unbalanced ROOTs would saturate
# sp_gc_nroots if they weren't matched by SP_GC_RESTORE.
sum = 0
i = 0
while i < 200
  vv = Vec.new(i, i + 1)
  sum = sum + vv.sum
  i = i + 1
end
puts sum                       # 200 * (i + (i+1)) summed = sum of (2i+1) for i=0..199 = 200*200 = 40000
