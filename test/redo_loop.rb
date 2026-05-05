# RedoNode -- `redo` inside Kernel#loop: re-runs body without
# advancing i. `break` terminates the otherwise-infinite loop.
i = 0
attempts = 0
loop do
  attempts += 1
  if i == 1 && attempts < 5
    redo
  end
  puts "i=#{i} attempt=#{attempts}"
  i += 1
  break if i >= 3
end
puts "total=#{attempts}"
