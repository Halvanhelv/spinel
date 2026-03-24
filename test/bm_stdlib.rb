# Test stdlib additions

# Array#join
arr = (1..5).to_a
puts arr.join(", ")  # 1, 2, 3, 4, 5

# Array#uniq
nums = (1..5).to_a
nums.push(3)
nums.push(1)
uniq = nums.uniq
puts uniq.length  # 5

# srand/rand
srand(0)
r = rand(100)
puts r >= 0  # true (some number)

# ARGV.length
puts ARGV.length  # 0

# $stderr.puts
$stderr.puts("stderr msg")

# exit — skip (would terminate)
# sleep — skip (would delay)

puts "done"
