# RedoNode -- `redo` inside Array#each_cons.
attempts = 0
[1, 2, 3, 4, 5].each_cons(2) do |pair|
  attempts += 1
  if pair == [2, 3] && attempts < 5
    redo
  end
  puts "pair=#{pair.inspect} attempt=#{attempts}"
end
puts "total=#{attempts}"
