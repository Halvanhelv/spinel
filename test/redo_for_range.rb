# RedoNode -- `redo` inside `for x in range`: re-runs body without
# advancing the loop variable.
attempts = 0
for i in 0..2
  attempts += 1
  if i == 1 && attempts < 5
    redo
  end
  puts "i=#{i} attempt=#{attempts}"
end
puts "total=#{attempts}"
