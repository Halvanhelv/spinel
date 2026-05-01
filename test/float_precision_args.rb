# Float#ceil(n), #floor(n), #round(n), #truncate(n) precision-arg
# variants. Bundle the four mirror-image methods — same shift-by-pow(10,n)
# pattern, same return-type rule (Float when n is given, Integer for the
# zero-arg form which already shipped).

# Float#round(n) - positive precision
puts 3.14159.round(2)
puts 3.14159.round(4)
puts 1.5.round(1)
puts 2.5.round(1)

# Float#ceil(n)
puts 3.14159.ceil(2)
puts 3.14159.ceil(4)
puts 1.001.ceil(2)

# Float#floor(n)
puts 3.14159.floor(2)
puts 3.14159.floor(4)
puts 1.999.floor(2)

# Float#truncate(n)
puts 3.14159.truncate(2)
puts 3.14159.truncate(4)
puts (-1.567).truncate(2)

# Zero-arg variants still return Integer
puts 3.14.round
puts 3.14.ceil
puts 3.14.floor
puts 3.14.truncate

# Negative precision rounds at digit positions BEFORE the decimal point.
# Values use bool-comparison output so the test is robust to CRuby's
# Integer-returning negative-precision rule vs. Spinel's uniform Float
# inference (the underlying values match; only the printed type differs).
puts 12345.6789.floor(-2) == 12300
puts 12345.6789.ceil(-2) == 12400
puts 12345.6789.round(-1) == 12350
puts 12345.6789.truncate(-2) == 12300
puts (-12345.6789).floor(-2) == -12400
puts (-12345.6789).ceil(-2) == -12300
