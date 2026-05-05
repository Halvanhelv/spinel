# RedoNode -- `redo` inside Integer#upto: re-runs body without
# advancing the block param.
attempts = 0
0.upto(2) do |i|
  attempts += 1
  if i == 1 && attempts < 5
    redo
  end
  puts "i=#{i} attempt=#{attempts}"
end
puts "total=#{attempts}"
