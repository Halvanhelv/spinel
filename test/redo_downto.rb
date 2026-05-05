# RedoNode -- `redo` inside Integer#downto: re-runs body without
# advancing the block param.
attempts = 0
2.downto(0) do |i|
  attempts += 1
  if i == 1 && attempts < 5
    redo
  end
  puts "i=#{i} attempt=#{attempts}"
end
puts "total=#{attempts}"
