# Test Fiber (cooperative concurrency)

# Basic yield/resume
f = Fiber.new {
  Fiber.yield(10)
  Fiber.yield(20)
  30
}
puts f.resume  # 10
puts f.resume  # 20
puts f.resume  # 30

# Value passing
f2 = Fiber.new { |first|
  second = Fiber.yield(first * 2)
  second * 3
}
puts f2.resume(5)   # 10
puts f2.resume(7)   # 21
