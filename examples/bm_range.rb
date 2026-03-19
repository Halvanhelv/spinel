r = (1..10)
puts r.first    # 1
puts r.last     # 10
puts r.include?(5)   # true
puts r.include?(11)  # false

arr = r.to_a
puts arr.length  # 10
puts arr.sum     # 55

total = 0
r.each do |i|
  total += i
end
puts total  # 55
puts "done"
