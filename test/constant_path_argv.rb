# Test ConstantPath access to ARGV methods.

puts ARGV.length
puts ::ARGV.length
puts(ARGV[0] == nil)
puts(::ARGV[0] == nil)
