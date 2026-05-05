# RedoNode -- `redo` inside while: re-runs the body without
# re-checking the guard or advancing i. The counter prevents
# infinite redo.
i = 0
attempts = 0
while i < 3
  attempts += 1
  if i == 1 && attempts < 5
    redo
  end
  puts "i=#{i} attempt=#{attempts}"
  i += 1
end
puts "total=#{attempts}"
