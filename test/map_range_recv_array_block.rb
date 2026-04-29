# `infer_method_name_type` for `map` used to fall through to
# `infer_type(recv)` when the block returned a non-trivial shape
# (an array literal, poly, etc.). For a Range recv that yielded
# `range`, poisoning any ivar holding the result; an
# `@x = something_else` assignment then failed to type-check
# (`@x = 0` against an `sp_Range` slot). The fix returns
# `int_array` as a generic placeholder for non-array recvs.

class C
  def initialize
    # Block returns an array literal — non-trivial bret. recv is
    # Range. Without the fix, @rows is typed as `range`, and the
    # follow-up assignment below produces a C compile error
    # ("incompatible types when assigning to type sp_Range").
    @rows = (0...3).map { |i| [i, i * 10] }
    @rows = [10, 20, 30]
  end

  def show
    @rows.each { |v| puts v }
  end
end

C.new.show
# Expected: 10 / 20 / 30
