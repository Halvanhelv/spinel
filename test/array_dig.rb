a = [10, 20, 30]
# In-bounds — first / middle / last.
p a.dig(0)
p a.dig(1)
p a.dig(2)
# Negative indices — counts from the end.
p a.dig(-1)
p a.dig(-3)
# Out-of-bounds dig isn't covered here. Ruby returns nil; Spinel's
# Array#[] inherits its existing in-bounds-only contract on int_array
# (the single-arg dig delegates to []), so out-of-bounds reads behave
# like out-of-bounds [] reads. Adding nil-returning bounds checks is
# a separate scope (would widen the result type to poly).
