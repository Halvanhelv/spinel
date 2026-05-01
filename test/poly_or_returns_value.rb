def pick(a, b)
  a || b
end

puts pick(nil, "fallback")
puts pick("actual", "fallback")

def pick_int(a, b)
  a || b
end

puts pick_int(0, 5)
puts(nil || "direct")
