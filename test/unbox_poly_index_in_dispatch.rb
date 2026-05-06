# `emit_poly_builtin_dispatch` referenced `arg_types` out of scope.
# Without the fix, `(poly_recv)[poly_idx]` produced
# `sp_PolyArray_get(arr, sp_RbVal_idx)` — passing sp_RbVal where
# mrb_int is expected and failing the C compile.
#
# Trigger: poly recv (from heterogeneous Hash) + poly idx (also).

class C
  def initialize
    @bag  = { "arr" => [100, 200, 300, 400], "lbl" => "x" }
    @keys = { "i" => 2, "s" => "lbl" }
  end
  def at(k)
    arr = @bag["arr"]      # poly
    idx = @keys[k]         # poly
    arr[idx]               # poly recv + poly idx
  end
end

puts C.new.at("i").to_s    # use .to_s (handled separately) instead of .to_i
