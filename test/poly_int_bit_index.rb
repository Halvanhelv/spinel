# `Integer#[N]` (bit-extraction) where the receiver was typed
# poly via cascading inference. Used to fall through to the
# SP_TAG_OBJ array dispatch in `emit_poly_builtin_dispatch`'s
# `[]` branch, leaving the result at the nil/0 default — so
# `int[i]` returned 0 for every i, and downstream
# `pc[8] == tmp[8] ? a : b` style page-bit checks always took
# the same-page branch.

class Holder
  # Mixed-type ivar writes widen @x to poly. Reads return sp_RbVal
  # even when the runtime value is concretely int.
  def initialize
    @x = "init"
    @x = 0b10110100  # 180 — actual value at test time
  end

  attr_reader :x

  # Same-page check pattern: extract bit 8 from each poly-typed int.
  def same_page?(a, b)
    a[8] == b[8]
  end
end

h = Holder.new
v = h.x  # `v` is poly here

# Static index, dynamic value. Without the fix, every output is 0.
puts v[0]    # 0
puts v[1]    # 0
puts v[2]    # 1
puts v[3]    # 0
puts v[4]    # 1
puts v[5]    # 1
puts v[6]    # 0
puts v[7]    # 1

# Dynamic index. Same buggy fallthrough.
i = 0
while i < 4
  puts v[i]
  i += 1
end

# Page-bit check: `0x100 | x` flips bit 8 on/off so the comparison
# meaningfully differs depending on input. With the bug both values
# get bit-8 == 0 (default), the comparison is always true, and
# branch-cycle counting collapses.
puts h.same_page?(h.x, h.x | 0x100)   # false (bit 8 differs)
puts h.same_page?(h.x, h.x | 0x10)    # true (bit 8 same — both 0)
