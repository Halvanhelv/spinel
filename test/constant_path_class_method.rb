# Test ConstantPath class method dispatch:
#   A::B.create(...)
#   ::A::B.create(...)

module A
  class B
    def self.create(x)
      x + 1
    end
  end
end

puts A::B.create(41)
puts ::A::B.create(99)
