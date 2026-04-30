# Array#tally for sym_array. str_array#tally already shipped — this
# extends it to symbol arrays via a sp_SymArray_tally runtime helper
# that produces a sym_int_hash mapping each unique element to its
# occurrence count.

# Basic tally over symbol array
puts [:a, :b, :a, :c, :a, :b].tally[:a]
puts [:a, :b, :a, :c, :a, :b].tally[:b]
puts [:a, :b, :a, :c, :a, :b].tally[:c]

# Single element
puts [:foo].tally[:foo]

# All same
puts [:x, :x, :x, :x].tally[:x]

# Length of result
puts [:a, :b, :a, :c, :a, :b].tally.length
puts [:foo].tally.length
puts [:x, :x, :x, :x].tally.length

# has_key? confirms membership
puts [:a, :b, :c].tally.has_key?(:a)
puts [:a, :b, :c].tally.has_key?(:z)
