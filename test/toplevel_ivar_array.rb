# Top-level instance variables: `@x` at script scope binds to the
# main object, the same as inside an instance method. Spinel currently
# emits `self->iv_x = ...` for ivar access but the script's top-level
# function has no `self` parameter, so the C compiler errors with
# `use of undeclared identifier 'self'`. The ivar read also falls
# through type inference and gets defaulted to `int`, producing a
# bogus "cannot resolve call to 'push' on int" warning before the
# hard error.

@n = 0
@n = @n + 1
@n = @n + 1
puts @n

@arr = []
@arr.push(7)
@arr.push(8)
puts @arr.length
@arr.each { |v| puts v }
