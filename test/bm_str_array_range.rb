# StrArray slicing: a[range] and a[start, len].
# Same regression class as IntArray: a[1..2] failed to compile and
# a[1, 2] silently dropped the second arg.

a = "alpha,beta,gamma,delta,epsilon".split(",")

# Range form
b = a[1..3]
puts b.length      # 3
puts b[0]          # beta
puts b[1]          # gamma
puts b[2]          # delta

# (start, len) form
c = a[1, 2]
puts c.length      # 2
puts c[0]          # beta
puts c[1]          # gamma

# Negative start
d = a[-2, 2]
puts d.length      # 2
puts d[0]          # delta
puts d[1]          # epsilon

# len exceeds remaining: clamped
f = a[2, 100]
puts f.length      # 3
puts f[0]          # gamma
puts f[2]          # epsilon

# Bare a[i] still returns a string
puts a[0]          # alpha
puts a[-1]         # epsilon

# Result is usable as a StrArray
puts a[1..3].join(":")  # beta:gamma:delta
