# `Array#clear` on typed arrays used to fall through the
# dispatcher and produce no C output, leaving the array
# unchanged. Zero the length (and `start` for IntArray, which
# uses a sliding window) so the next push refills from index 0.

# IntArray
ints = [1, 2, 3]
ints.clear
puts ints.length    # 0
ints.push(7)
puts ints[0]        # 7

# SymArray (shares IntArray internally)
syms = [:a, :b, :c]
syms.clear
puts syms.length    # 0

# FloatArray
floats = [1.5, 2.5, 3.5]
floats.clear
puts floats.length  # 0

# StrArray
strs = ["a", "b", "c"]
strs.clear
puts strs.length    # 0

# PtrArray (array of objects)
class Box
  attr_reader :n
  def initialize(n); @n = n; end
end
boxes = [Box.new(1), Box.new(2)]
boxes.clear
puts boxes.length   # 0

# PolyArray (mixed-type elements)
mixed = [1, "x", :sym, 4.5]
mixed.clear
puts mixed.length   # 0
