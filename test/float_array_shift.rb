# FloatArray#shift removes and returns the first element. The
# IntArray helper existed; FloatArray's was missing and the codegen
# fell through to the unknown-method 0 fallback.

arr = [1.5, 2.5, 3.5, 4.5]
puts arr.shift     # 1.5
puts arr.length    # 3
puts arr[0]        # 2.5

# Drain via repeated shift.
while arr.length > 0
  puts arr.shift
end
puts arr.length    # 0
