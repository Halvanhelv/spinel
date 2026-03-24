# Test module constants and top-level constants

MAX_SIZE = 100
PI_APPROX = 3
NAME = "spinel"

module Config
  VERSION = 42
  GREETING = "hello"
  ENABLED = true
end

puts MAX_SIZE         # 100
puts PI_APPROX        # 3
puts NAME             # spinel
puts Config::VERSION  # 42
puts Config::GREETING # hello
puts Config::ENABLED  # true

# Constants in expressions
puts MAX_SIZE + 1     # 101
puts NAME.length      # 6
puts Config::GREETING.upcase  # HELLO

puts "done"
