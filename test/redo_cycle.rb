# RedoNode -- `redo` inside Array#cycle (with a count to terminate).
attempts = 0
[1, 2].cycle(2) do |x|
  attempts += 1
  if x == 1 && attempts < 3
    redo
  end
  puts "x=#{x} attempt=#{attempts}"
end
puts "total=#{attempts}"
