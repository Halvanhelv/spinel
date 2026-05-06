# Float and FloatArray coverage — to_s formatting, FloatArray
# reductions / slicing / shift, and Float#ceil/floor/round/truncate
# with a precision arg. Was five separate tests; merged. No class
# collisions; locals reused across the originals (`f`, `arr`, `a`)
# get per-section prefixes so spinel's local-type inference doesn't
# unify them.

# === FloatArray reductions: min / max / sum / first / last ===
fr_arr = [1.5, 2.5, 0.5, 3.5]
puts fr_arr.min     # 0.5
puts fr_arr.max     # 3.5
puts fr_arr.first   # 1.5
puts fr_arr.last    # 3.5

fr_neg = [-1.5, -3.25, 2.75]
puts fr_neg.min     # -3.25
puts fr_neg.max     # 2.75

fr_one = [4.5]
puts fr_one.min     # 4.5
puts fr_one.max     # 4.5

# Sum with non-integer-valued result (avoids the stale-type truncation
# that would print "4" instead of "4.5").
fr_sum = [1.5, 2.5, 0.5]
puts fr_sum.sum     # 4.5

# === FloatArray slicing: a[range] and a[start, len] ===
fs_a = [1.5, 2.5, 3.5, 4.5, 5.5]
fs_b = fs_a[1..3]
puts fs_b.length    # 3
puts fs_b[0]        # 2.5
puts fs_b[1]        # 3.5
puts fs_b[2]        # 4.5
fs_c = fs_a[1, 2]
puts fs_c.length    # 2
puts fs_c[0]        # 2.5
puts fs_c[1]        # 3.5
fs_d = fs_a[-2, 2]
puts fs_d.length    # 2
puts fs_d[0]        # 4.5
puts fs_d[1]        # 5.5
fs_e = fs_a[2, 100]
puts fs_e.length    # 3 (clamped)
puts fs_e[0]        # 3.5
puts fs_e[2]        # 5.5
puts fs_a[0]        # 1.5
puts fs_a[-1]       # 5.5
puts fs_a[1..3].sum # 10.5

# === FloatArray#shift ===
fsh_arr = [1.5, 2.5, 3.5, 4.5]
puts fsh_arr.shift  # 1.5
puts fsh_arr.length # 3
puts fsh_arr[0]     # 2.5
while fsh_arr.length > 0
  puts fsh_arr.shift
end
puts fsh_arr.length # 0

# === Float#ceil/floor/round/truncate with precision arg ===
puts 3.14159.round(2)
puts 3.14159.round(4)
puts 1.5.round(1)
puts 2.5.round(1)
puts 3.14159.ceil(2)
puts 3.14159.ceil(4)
puts 1.001.ceil(2)
puts 3.14159.floor(2)
puts 3.14159.floor(4)
puts 1.999.floor(2)
puts 3.14159.truncate(2)
puts 3.14159.truncate(4)
puts (-1.567).truncate(2)
puts 3.14.round
puts 3.14.ceil
puts 3.14.floor
puts 3.14.truncate
# Negative precision: bool-compare for type-stable output across
# CRuby's Integer-return rule vs. Spinel's uniform Float inference.
puts 12345.6789.floor(-2) == 12300
puts 12345.6789.ceil(-2) == 12400
puts 12345.6789.round(-1) == 12350
puts 12345.6789.truncate(-2) == 12300
puts (-12345.6789).floor(-2) == -12400
puts (-12345.6789).ceil(-2) == -12300

# === Float#to_s / p / puts byte-identical output ===
# Shortest decimal that round-trips; fixed-point inside CRuby's
# [-4, 15] decimal-exponent window, scientific (`d.ddde+NN`)
# outside.
puts 1.0
puts 100.0
puts(-3.25)
puts 1234567890.0
puts 1234567890.5
puts 0.1
puts 0.3
puts 0.30000000000000004
puts 0.0001
puts 0.00001
puts 1.5e14
puts 1.0e15
puts 9.99e15
puts 1.0e16
puts 1.0e100
puts(-0.0)
puts Float::INFINITY
puts(-Float::INFINITY)
puts Float::NAN
p 1.0
p 1234567890.5
p 1.0e16
p(-0.0)

# === Kernel#Float coerces strings, ints, and floats ===
puts Float("3.14")        # 3.14
puts Float("0")           # 0.0
puts Float("-2.5")        # -2.5
puts Float(1)             # 1.0
puts Float(42)            # 42.0
puts Float(2.71)          # 2.71
puts Float("1e2")         # 100.0
