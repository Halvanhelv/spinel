# RedoNode -- nested redo across mixed loop kinds. Outer = while,
# inner = times. Inner redo re-runs only the inner iteration; outer
# counter must not be re-bumped. Exercises label-stack uniqueness.
inner_attempts = 0
outer_done = 0
i = 0
while i < 2
  outer_done += 1
  3.times do |j|
    inner_attempts += 1
    if i == 0 && j == 1 && inner_attempts < 4
      redo
    end
    puts "i=#{i} j=#{j} attempt=#{inner_attempts}"
  end
  i += 1
end
puts "outer_done=#{outer_done}"
puts "inner_attempts=#{inner_attempts}"
