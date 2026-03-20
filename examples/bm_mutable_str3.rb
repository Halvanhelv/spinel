# Test sp_String (mutable string) additional methods

s = ""
s << "Hello"
s << " "
s << "World"
puts s.length       # 11
puts s.downcase     # hello world
puts s.strip        # Hello World
puts s.capitalize   # Hello world

puts s.start_with?("Hello")  # true
puts s.end_with?("World")    # true
puts s.empty?                 # false

# sub / gsub
puts s.gsub("l", "r")        # Herro Worrd
puts s.sub("World", "Ruby")  # Hello Ruby

# to_i / to_f
n = ""
n << "42"
puts n.to_i    # 42

# ljust / rjust
t = ""
t << "hi"
puts t.ljust(10)   # "hi        "
puts t.rjust(10)   # "        hi"

# include?
puts s.include?("World")  # true
puts s.include?("xyz")    # false

puts "done"
