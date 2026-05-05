# Integer bit-test predicates: allbits? / nobits? / anybits?. Three
# parallel methods (true iff the bits in the mask are: all set / all
# clear / any set on the receiver). Same coverage matrix per method:
# basic, no-overlap / subset, zero mask, single bit, large value,
# negative receiver. Was three near-identical files.

# === allbits? ===
puts 255.allbits?(255)
puts 255.allbits?(128)
puts 0.allbits?(0)
puts 42.allbits?(0)
puts 5.allbits?(6)
puts 8.allbits?(3)
puts 4.allbits?(4)
puts 4.allbits?(2)
puts 0xFFFF.allbits?(0xFF00)
puts((-1).allbits?(255))
puts 0.allbits?(1)

# === nobits? ===
puts 256.nobits?(1)
puts 256.nobits?(255)
puts 8.nobits?(4)
puts 255.nobits?(1)
puts 6.nobits?(2)
puts 0.nobits?(0)
puts 42.nobits?(0)
puts 4.nobits?(2)
puts 4.nobits?(4)
puts((-1).nobits?(1))
puts((-4).nobits?(2))
puts 0xFF00.nobits?(0x00FF)

# === anybits? ===
puts 255.anybits?(128)
puts 255.anybits?(1)
puts 0.anybits?(1)
puts 16.anybits?(8)
puts 4.anybits?(2)
puts 0.anybits?(0)
puts 42.anybits?(0)
puts 6.anybits?(4)
puts 6.anybits?(2)
puts((-1).anybits?(1))
puts((-4).anybits?(4))
puts 0xFF00.anybits?(0x0100)
