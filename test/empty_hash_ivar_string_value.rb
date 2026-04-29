# Issue #64: an ivar initialized as `{}` defaulted to `str_int_hash`,
# and a later `@h[k] = "string"` write fed `const char *` into
# `sp_StrIntHash_set` (which expects `mrb_int`). Three pieces of the
# fix:
#   - scan_writer_calls now recognises `@h[k] = v` against an ivar
#     still typed as the empty-hash default and promotes the slot
#     based on the actual key/value types
#   - the same scanner skips empty `{}` / `[]` writes when re-scanning
#     so the iterative loop doesn't widen the promoted type back to
#     poly via "old=str_str_hash, new=str_int_hash"
#   - both compile_stmt(InstanceVariableWriteNode) and the inline
#     constructor walker route empty `{}` against a promoted ivar to
#     the matching `sp_*Hash_new()` ctor

class Sources
  def initialize
    @file_sources = {}
    @current_file = "a.rb"
  end

  def add(source)
    @file_sources[@current_file] = source if @current_file
  end

  def lookup(name)
    @file_sources[name]
  end
end

s = Sources.new
s.add("body")
puts s.lookup("a.rb")        # body
puts s.lookup("missing")     # (empty line — string hash default for missing key)

# The other key/value-type combos covered by the same promotion path.
class IntKeyed
  def initialize; @h = {}; end
  def put(k, v); @h[k] = v; end
  def get(k); @h[k]; end
end

ik = IntKeyed.new
ik.put(7, "seven")
ik.put(42, "forty-two")
puts ik.get(7)               # seven
puts ik.get(42)              # forty-two

# Symbol-keyed promotion is also wired through but exercises a
# pre-existing -Walloc-size-larger-than warning in the runtime
# `sp_SymIntHash_grow` (unrelated to this issue), so it isn't part
# of the make-test surface here.
