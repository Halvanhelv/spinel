# RedoNode -- `redo` inside Array#each: re-runs body without
# advancing the iterator.
attempts = 0
[10, 20, 30].each do |x|
  attempts += 1
  if x == 20 && attempts < 5
    redo
  end
  puts "x=#{x} attempt=#{attempts}"
end
puts "total=#{attempts}"
