# Issue #204: user-defined `find` / `fetch` were overridden by the
# method-name dispatch's "int" fallback even when the receiver
# wasn't a built-in collection. The body's actual return type
# (string here) lost; the call site mistyped the result as int.

# Class method form (canonical ActiveRecord finder shape).
class Bag
  def self.find(id); "row-#{id}"; end
  def self.fetch(id); "fetched-#{id}"; end
end
puts Bag.find(42)        # row-42
puts Bag.fetch(99)       # fetched-99

# Instance method form on a hash-wrapping class.
class C
  def initialize(h); @h = h; end
  def find(key); @h[key.to_sym]; end
  def fetch(key); @h[key.to_sym]; end
end
c = C.new({a: "alpha", b: "beta"})
puts c.find(:a)          # alpha
puts c.fetch(:b)         # beta

# Built-in collection dispatch still works (regression check).
puts ["x", "y", "z"].find { |v| v == "y" }   # y
