# Test lrama-required features (part 2)

# A9: Hash#merge (sp_StrIntHash)
h1 = {"a" => 1, "b" => 2}
h2 = {"b" => 3, "c" => 4}
h3 = h1.merge(h2)
puts h3["a"]  # 1
puts h3["b"]  # 3  (h2 overrides h1)
puts h3["c"]  # 4

# A19: Array#dup (already works)
arr = [10, 20, 30]
arr2 = arr.dup
puts arr2[0]  # 10
puts arr2.length  # 3

# A19: String#dup (const string)
s1 = "hello"
s2 = s1.dup
puts s2  # hello

# A20: Hash.new(0) with default value
counter = Hash.new(0)
counter["x"] = counter["x"] + 1
counter["x"] = counter["x"] + 1
counter["y"] = counter["y"] + 1
puts counter["x"]  # 2
puts counter["y"]  # 1
puts counter["z"]  # 0 (default)

# B2: attr_writer
class Writer
  attr_reader :name
  attr_writer :name
  def initialize(n)
    @name = n
  end
end
w = Writer.new("before")
puts w.name  # before
w.name = "after"
puts w.name  # after

# B3: Comparable (include Comparable + def <=>)
class Weight
  include Comparable
  attr_reader :grams
  def initialize(g)
    @grams = g
  end
  def <=>(other)
    @grams - other.grams
  end
end

w1 = Weight.new(100)
w2 = Weight.new(200)
w3 = Weight.new(100)
puts w1 < w2    # true
puts w2 > w1    # true
puts w1 == w3   # true
puts w1 > w2    # false
puts w1 <= w3   # true
puts w2 >= w1   # true

puts "done"
