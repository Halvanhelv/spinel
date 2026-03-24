# yjit-bench: respond_to - respond_to? call performance
# Ported from https://github.com/Shopify/yjit-bench

class A
  def initialize
    @id = 1
  end

  def foo
    nil
  end

  def foo2
    nil
  end
end

a = A.new

count_true = 0
count_false = 0

i = 0
while i < 500000
  count_true = count_true + 1 if a.respond_to?(:foo)
  count_true = count_true + 1 if a.respond_to?(:foo2)
  count_false = count_false + 1 if a.respond_to?(:bar)
  count_false = count_false + 1 if a.respond_to?(:bar2)
  i = i + 1
end

puts count_true
puts count_false
