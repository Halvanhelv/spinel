# Process.clock_gettime(Process::CLOCK_MONOTONIC) returns a Float.
# We can't assert an exact value, but we can verify the call lowers
# correctly (returns a float, monotonic non-decreasing across two
# samples).

t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

# t1 and t2 must be Float-typed in spinel; arithmetic should work.
diff = t2 - t1
if diff >= 0
  puts "monotonic"
end
