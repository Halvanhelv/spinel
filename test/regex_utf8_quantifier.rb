# Issue #61 stage 5: `[utf8 chars]+` (or any quantifier over a class
# whose match consumes a multi-byte char) was matching one char per
# attempt instead of greedily consuming the whole run. Cause: the
# Pike VM's outer loop steps the input pointer one byte at a time,
# but a class match over a UTF-8 char advances 3 bytes — the retry
# thread enqueued at sp+3 ran at sp+1 (mid-multibyte) on the next
# outer iteration and died.
#
# Fix: each thread carries its own input position. The outer loop
# defers a thread to a later iteration when its sp doesn't yet match
# the loop's sp.

# Greedy + over a UTF-8 class — the heart of the bug.
puts "abc₁₂def".gsub(/[₀-₉]+/, "N")          # abcNdef (one match, not "NN")
puts "abc₁₂₃def".gsub(/[₀-₉]+/, "N")        # abcNdef
puts "₁abc₂₃def₄₅₆".scan(/[₀-₉]+/).length  # 3 (one per run)

# Repeat counts on UTF-8 char class.
puts "₀₁".match?(/[₀-₉]{2}/) ? "ok2" : "fail2"
puts "₀".match?(/[₀-₉]{2}/) ? "fail3" : "ok3"

# Mixed ASCII/UTF-8 + quantifier.
puts "a₁b₂c".scan(/[a-z₀-₉]+/).length        # 1 (whole string)

# *? non-greedy across UTF-8 chars.
puts "₁₂₃".scan(/[₀-₉]/).length              # 3 (one char each)

# Ranges crossing into utf8.
puts "αβ".match?(/[α-ω]+/) ? "ok7" : "fail7"
