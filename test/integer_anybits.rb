# basic
puts 255.anybits?(128)
puts 255.anybits?(1)

# no overlap
puts 0.anybits?(1)
puts 16.anybits?(8)
puts 4.anybits?(2)

# zero mask
puts 0.anybits?(0)
puts 42.anybits?(0)

# single bit match
puts 6.anybits?(4)
puts 6.anybits?(2)

# negative
puts((-1).anybits?(1))
puts((-4).anybits?(4))

# large value
puts 0xFF00.anybits?(0x0100)
