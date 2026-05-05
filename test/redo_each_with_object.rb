# RedoNode -- `redo` inside Array#each_with_object.
# Note: redo is goto-style, so a partial mutation to the accumulator
# before redo persists. The counter pattern below avoids touching
# the accumulator on the redo path so the result is deterministic.
attempts = 0
result = [1, 2, 3].each_with_object([]) do |x, acc|
  attempts += 1
  if x == 2 && attempts < 5
    redo
  end
  acc << x * 10
end
puts result.inspect
puts "total=#{attempts}"
