# `Array#transpose` codegen creates the result `sp_PtrArray` and
# inner `sp_IntArray` columns without `SP_GC_ROOT`. With many
# allocations across the loop, an `sp_gc_collect` triggered by
# the next column's `sp_IntArray_new()` reclaims the unrooted
# result PtrArray. The next `sp_PtrArray_push(result, col)`
# dereferences a freed pointer.
#
# Trigger: a transpose of a large array-of-arrays. Optcarrot's
# `(0..7).map { (0...0x10000).map {...} }.transpose` allocates
# 8 outer + 65536 × 8 inner ints in close succession.

big = (0..7).map { |a| (0..1023).map { |b| a * 1000 + b } }.transpose
puts big.length        # 1024
puts big[0].length     # 8
puts big[100][3]       # 3*1000 + 100 = 3100
puts big[1023][7]      # 7*1000 + 1023 = 8023
