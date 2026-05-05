# RedoNode -- `redo` inside Array#each_slice. Each slice is a fresh
# array on every (re)iteration; counter prevents infinite redo.
attempts = 0
[1, 2, 3, 4, 5, 6].each_slice(2) do |slice|
  attempts += 1
  if slice == [3, 4] && attempts < 5
    redo
  end
  puts "slice=#{slice.inspect} attempt=#{attempts}"
end
puts "total=#{attempts}"
