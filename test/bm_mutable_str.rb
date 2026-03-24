# Test mutable strings (sp_String)

# String << (true mutation, not reassignment)
s = "hello"
s << " world"
s << "!"
puts s          # hello world!
puts s.length   # 12

# Build string incrementally
buf = ""
5.times do |i|
  buf << i.to_s
  buf << ","
end
puts buf        # 0,1,2,3,4,

# String methods on mutable string
s2 = "Hello World"
puts s2.upcase   # HELLO WORLD
puts s2.reverse  # dlroW olleH
puts s2.include?("World")  # true

puts "done"
