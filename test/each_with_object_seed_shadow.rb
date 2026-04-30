# Array#each_with_object: the seed (second block param) must shadow an
# outer same-named local of a different type. Without push_scope/
# declare_var on the seed, infer_type inside the block resolves against
# the outer binding and dispatches the wrong runtime call.

def f
  obj = 42
  out = [1, 2, 3].each_with_object([]) { |x, obj| obj.push(x * 2) }
  puts out[0]   # 2
  puts out[1]   # 4
  puts out[2]   # 6
  puts obj      # 42
end
f
