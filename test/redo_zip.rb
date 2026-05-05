# RedoNode -- `redo` inside Array#zip with a block.
attempts = 0
[1, 2, 3].zip([10, 20, 30]) do |a, b|
  attempts += 1
  if a == 2 && attempts < 5
    redo
  end
  puts "a=#{a} b=#{b} attempt=#{attempts}"
end
puts "total=#{attempts}"
