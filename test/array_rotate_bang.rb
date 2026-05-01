# Array#rotate!(n): in-place left rotation by n positions.
# Previously the bang form was not dispatched at all and the codegen
# emitted a no-op, so `rotate!` left the array untouched.

# IntArray
ints = [1, 2, 3, 4, 5]
ints.rotate!(2)
ints.each { |i| puts i }   # 3 4 5 1 2

# Negative n rotates right.
ints2 = [1, 2, 3, 4, 5]
ints2.rotate!(-1)
ints2.each { |i| puts i }  # 5 1 2 3 4

# n larger than length wraps modulo len.
ints3 = [1, 2, 3]
ints3.rotate!(7)
ints3.each { |i| puts i }  # 2 3 1

# Empty array is a no-op (no malloc, no crash).
empty = []
empty.rotate!(3)
puts empty.length          # 0

# SymArray (shares the IntArray helper internally).
syms = [:a, :b, :c, :d]
syms.rotate!(1)
syms.each { |s| puts s }   # b c d a

# FloatArray
floats = [1.5, 2.5, 3.5, 4.5]
floats.rotate!(2)
floats.each { |f| puts f } # 3.5 4.5 1.5 2.5

# StrArray
strs = ["a", "b", "c", "d"]
strs.rotate!(1)
strs.each { |s| puts s }   # b c d a

# PtrArray (array of objects)
class Box
  attr_reader :n
  def initialize(n)
    @n = n
  end
end
boxes = [Box.new(10), Box.new(20), Box.new(30), Box.new(40)]
boxes.rotate!(2)
boxes.each { |b| puts b.n } # 30 40 10 20

# PolyArray (mixed-type elements)
mixed = [1, "x", :sym, 4.5]
mixed.rotate!(1)
mixed.each { |v| puts v }   # x sym 4.5 1
