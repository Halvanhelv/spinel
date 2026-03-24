# Spectral norm benchmark (from Ruby benchmark suite)

def eval_a(i, j)
  1.0 / ((i + j) * (i + j + 1) / 2 + i + 1)
end

def eval_a_times_u(u, n)
  v = Array.new(n, 0.0)
  i = 0
  while i < n
    s = 0.0
    j = 0
    while j < n
      s = s + eval_a(i, j) * u[j]
      j = j + 1
    end
    v[i] = s
    i = i + 1
  end
  v
end

def eval_at_times_u(u, n)
  v = Array.new(n, 0.0)
  i = 0
  while i < n
    s = 0.0
    j = 0
    while j < n
      s = s + eval_a(j, i) * u[j]
      j = j + 1
    end
    v[i] = s
    i = i + 1
  end
  v
end

def eval_ata_times_u(u, n)
  eval_at_times_u(eval_a_times_u(u, n), n)
end

n = 500
u = Array.new(n, 1.0)
iter = 0
while iter < 10
  v = eval_ata_times_u(u, n)
  u = eval_ata_times_u(v, n)
  iter = iter + 1
end

vbv = 0.0
vv = 0.0
i = 0
while i < n
  vbv = vbv + u[i] * v[i]
  vv = vv + v[i] * v[i]
  i = i + 1
end

puts (Math.sqrt(vbv / vv) * 1000000000).to_i
puts "done"
