# Disagreeing call-site types for the same parameter need to widen
# to `poly`. Pre-fix, `scan_new_calls` (obj-recv) and
# `scan_cls_method_calls` (self-call inside the same class) both
# only widened FROM "int": once the first non-int call site set the
# param type, subsequent disagreeing calls were silently accepted
# and the C compiler rejected the eventual mismatched call.
#
# Once the param widens to `poly`, the int / pointer / etc. arguments
# at the call sites need to be boxed via `sp_box_*`. That boxing
# branch was also missing from `compile_typed_call_args`, so even
# after unify produced "poly", the call sites still passed raw
# mrb_int / pointers to a sp_RbVal-typed parameter.

class CPU
  def feed(x, val)
    val
  end
  # Self-call (no receiver). Lands in scan_cls_method_calls.
  def boot
    feed("hello", 1)
    feed(20, 2)
    feed("world", 3)
  end
end

class User
  def initialize(cpu)
    @cpu = cpu
  end
  # Obj-recv call. Lands in scan_new_calls' obj branch.
  def reset
    @cpu.feed(100, 10)
    @cpu.feed("via_user", 20)
    @cpu.feed(500, 30)
  end
end

cpu = CPU.new
puts cpu.boot
puts User.new(cpu).reset
