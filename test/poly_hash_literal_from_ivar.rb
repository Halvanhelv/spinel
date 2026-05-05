# Issue #287: a method that returns `{ key: @x, ... }` had its
# inferred return type frozen at the first scan, before #247 widened
# the ivar slot to poly via a sibling-writer disagreement. The hash
# literal then emitted as `sp_StrIntHash *` (int-valued) and tried
# to insert the now-poly ivar value at C compile time.
#
# Fix: extend `infer_hash_val_type`'s all_same branch to handle
# `first_vt == "poly"` — sym/str-keyed poly hashes get the same
# *_poly_hash storage as the mixed-types `else` branch.

class C
  def initialize
    @x = 0
  end
  def write_str(s)
    @x = s
  end
  def hash_of_x
    { key: @x }
  end
end

c = C.new
c.write_str("hello")
puts c.hash_of_x.size       # 1
puts c.hash_of_x.has_key?(:key)  # true

# Multiple sym-keyed entries, all flowing from poly ivars.
class D
  def initialize
    @a = 0
    @b = 0
  end
  def write(sa, sb)
    @a = sa
    @b = sb
  end
  def attrs
    { a: @a, b: @b }
  end
end

d = D.new
d.write("alpha", "beta")
puts d.attrs.size           # 2
puts d.attrs.has_key?(:a)   # true
puts d.attrs.has_key?(:c)   # false
