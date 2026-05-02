# all bits set
puts 255.allbits?(255)

# subset of bits
puts 255.allbits?(128)

# zero mask
puts 0.allbits?(0)
puts 42.allbits?(0)

# not all bits present
puts 5.allbits?(6)
puts 8.allbits?(3)

# single bit
puts 4.allbits?(4)
puts 4.allbits?(2)

# large value
puts 0xFFFF.allbits?(0xFF00)

# negative (all bits set)
puts((-1).allbits?(255))
puts 0.allbits?(1)
