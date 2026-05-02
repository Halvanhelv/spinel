# no overlap
puts 256.nobits?(1)
puts 256.nobits?(255)
puts 8.nobits?(4)

# overlap exists
puts 255.nobits?(1)
puts 6.nobits?(2)

# zero mask
puts 0.nobits?(0)
puts 42.nobits?(0)

# single bit
puts 4.nobits?(2)
puts 4.nobits?(4)

# negative
puts((-1).nobits?(1))
puts((-4).nobits?(2))

# large value
puts 0xFF00.nobits?(0x00FF)
