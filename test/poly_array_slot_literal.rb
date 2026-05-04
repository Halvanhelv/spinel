# `@arr = [a, b]` going into a poly_array slot used to compile the
# rhs via `compile_array_literal`, which infers a typed storage
# (ptr_array of one class for homogeneous obj literals, etc.) and
# emits the matching `sp_PtrArray *`. The slot is `sp_PolyArray *`
# (widened by writer-scan via heterogeneous `@arr[i] = v` writes
# elsewhere in the class), so the resulting C contains a pointer-
# type mismatch:
#
#   sp_PtrArray *_t1 = sp_PtrArray_new();
#   sp_PtrArray_push(_t1, sp_Pad_new());
#   self->iv_pads = _t1;          /* iv_pads is sp_PolyArray * */
#
# The default `-Wno-all` build accepts the cast silently and
# coerces, but strict flags reject it as
# `assignment to 'sp_PolyArray *' from incompatible pointer type
# 'sp_PtrArray *'`. Even under `-Wno-all` the runtime is wrong:
# `PolyArray_set` writes 16-byte sp_RbVal entries into 8-byte
# PtrArray slots and silently corrupts adjacent memory.

class Pad
  def initialize(n)
    @n = n
    @arr = []
    @arr << n
  end
  attr_reader :n
end

class Holder
  def initialize
    @pads = [Pad.new(10), Pad.new(20)]
    @pads[0] = "x"   # heterogeneous []= → @pads widens to poly_array
  end
  attr_reader :pads

  def count
    @pads.length
  end
end

puts Holder.new.count    # 2
