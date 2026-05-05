# `compile_bracket_assign` had no `rt == "poly"` branch. When an
# ivar slot widens to plain `poly` (sp_RbVal — wider than
# poly_array, set by `finalize_ivar_heterogeneity` because of
# multiple distinct non-array writes), `@arr[i] = v` falls through
# every typed branch and emits *nothing* — the assignment silently
# drops from generated C.
#
# Trigger: @arr is observed as int_array (`[nil] * N`) AND as a
# scalar (string, int) — finalize collapses to plain `poly`. Then
# `@arr[i] = v` should still write to the underlying storage, but
# without the poly arm spinel emits zero code for the assignment.

class C
  def init_arr(n)
    @arr = [nil] * n      # int_array observation
    @arr[0] = 100
  end
  def init_str
    @arr = "scalar"       # string observation — widens slot to poly
  end
  def init_int
    @arr = 42             # int observation
  end
  def at(i)
    @arr[i]
  end
end

c = C.new
c.init_arr(3)
puts c.at(0)              # post-write: 100 (master: 0 — write dropped)
