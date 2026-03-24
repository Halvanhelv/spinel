# Test lrama-required features (part 3): A10, A11, A18

# A10: Hash#transform_values (sp_StrIntHash)
h = {"a" => 1, "b" => 2, "c" => 3}
h2 = h.transform_values { |v| v * 10 }
puts h2["a"]  # 10
puts h2["b"]  # 20
puts h2["c"]  # 30
# Original unchanged
puts h["a"]   # 1

# A18: Array#zip
a = [1, 2, 3]
b = [4, 5, 6]
zipped = a.zip(b)
puts zipped.length  # 3

# Zip with different lengths
c = [10, 20]
zipped2 = a.zip(c)
puts zipped2.length  # 3

puts "done"
