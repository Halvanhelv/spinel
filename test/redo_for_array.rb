# RedoNode -- `redo` inside `for x in array`: re-runs body without
# advancing the iterator. Use an int-typed array so spinel infers
# `int_array`.
arr = [10, 20, 30]
attempts = 0
for x in arr
  attempts += 1
  if x == 20 && attempts < 5
    redo
  end
  puts "x=#{x} attempt=#{attempts}"
end
puts "total=#{attempts}"
