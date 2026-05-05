# RedoNode -- `redo` inside Array#each_with_index.
attempts = 0
[10, 20, 30].each_with_index do |x, i|
  attempts += 1
  if i == 1 && attempts < 5
    redo
  end
  puts "x=#{x} i=#{i} attempt=#{attempts}"
end
puts "total=#{attempts}"
