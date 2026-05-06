# `compile_call_expr` and `compile_mutating_call_stmt` had no `<<`
# / `push` arms for poly_array recv. The expr-context fall-through
# produced raw C `<<` on `sp_PolyArray *` (gcc error: "invalid
# operands to binary <<"); the stmt-context fall-through silently
# dropped the push from generated C entirely.
#
# Repro: a heterogeneous literal lowers to poly_array; then both
# `arr << v` (expr / stmt-without-receiver-rewrite) and
# `arr.push(v)` exercise the dispatch.

arr = [1, "two", :three]
arr << 42
arr.push("four")
puts arr.length
puts arr[0]
puts arr[1]
puts arr[2]
puts arr[3]
puts arr[4]
