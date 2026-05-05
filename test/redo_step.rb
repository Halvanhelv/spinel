# RedoNode -- `redo` inside Integer#step.
attempts = 0
1.step(7, 2) do |i|
  attempts += 1
  if i == 3 && attempts < 5
    redo
  end
  puts "i=#{i} attempt=#{attempts}"
end
puts "total=#{attempts}"
