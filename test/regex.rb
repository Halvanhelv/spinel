# Regex coverage — issue #61's five stages plus literal-form
# tests. Was six tests; class names didn't collide and the only
# top-level `def` (regex_local_var's `find`) is unique within this
# file. Local-name collisions (`re`, `re2` reused across files for
# different regex literals) are dodged with per-section prefixes
# so spinel's local-type inference doesn't unify them across the
# script and widen to poly.

# === Stage 1: UTF-8 source byte-length ===
# A regex source containing multi-byte UTF-8 chars must reach the
# runtime with the correct byte length. This section just verifies
# the binary runs past regex init.
re_s1a = /[₀₁₂₃₄₅₆₇₈₉]+/
re_s1b = /\A→\z/
re_s1c = /[αβγ]/
puts "ok"

# === Stage 2: UTF-8 character class ===
puts(("₁" =~ /[₀-₉]/) ? "ok1" : "fail1")
puts(("α" =~ /[α-ω]/) ? "ok2" : "fail2")
puts(("abc₁def" =~ /[₀₁₂₃₄₅₆₇₈₉]+/) ? "ok3" : "fail3")
puts(("a"  =~ /[^₀-₉]/) ? "ok4" : "fail4")
puts(("₁" =~ /[^₀-₉]/) ? "fail5" : "ok5")
puts(("z"  =~ /[a-z₀-₉]/) ? "ok6" : "fail6")
puts(("₅" =~ /[a-z₀-₉]/) ? "ok7" : "fail7")
puts(("₁" =~ /[α-ω]/) ? "fail8" : "ok8")
puts(("a"  =~ /[α-ω]/) ? "fail9" : "ok9")
m_s2 = "abc₁₂₃def" =~ /[₀-₉]+/
puts(m_s2 ? "ok10" : "fail10")

# === Stage 3: regex via constant ===
RX = /[₀₁₂₃₄₅₆₇₈₉ₐₑₒₓₔ]+/
puts RX.match?("₁₂")
puts RX.match?("abc")
if "₁₂" =~ RX
  puts "lhs match"
else
  puts "lhs miss"
end
if RX =~ "₁₂"
  puts "rhs match"
else
  puts "rhs miss"
end
m_s3 = RX.match("₁₂")
puts m_s3 ? "match ok" : "match fail"

# === Stage 4: regex via local variable ===
re_lv = /[₀₁₂₃₄₅₆₇₈₉]+/
puts re_lv.match?("₁₂")
puts re_lv.match?("abc")
if "abc₁def" =~ re_lv
  puts "lhs match"
else
  puts "lhs miss"
end
if re_lv =~ "abc₁def"
  puts "rhs match"
else
  puts "rhs miss"
end

# Inside a method body — fresh scope, fresh local.
def find(s)
  rx = /[a-z]+/
  rx.match?(s)
end
puts find("hello")
puts find("123")

# Multi-write disqualifies dispatch; the fall-through still compiles.
re2_lv = /a/
re2_lv = "not a regex"
puts re2_lv

# === Stage 5: UTF-8 quantifier ===
puts "abc₁₂def".gsub(/[₀-₉]+/, "N")
puts "abc₁₂₃def".gsub(/[₀-₉]+/, "N")
puts "₁abc₂₃def₄₅₆".scan(/[₀-₉]+/).length
puts "₀₁".match?(/[₀-₉]{2}/) ? "ok2" : "fail2"
puts "₀".match?(/[₀-₉]{2}/) ? "fail3" : "ok3"
puts "a₁b₂c".scan(/[a-z₀-₉]+/).length
puts "₁₂₃".scan(/[₀-₉]/).length
puts "αβ".match?(/[α-ω]+/) ? "ok7" : "fail7"

# === Multi-line / escape patterns ===
re_ml1 = /
  bar
/x
if re_ml1 =~ "barbar"
  puts "ok1"
else
  puts "no1"
end

re_ml_t = /a\tb/
if re_ml_t =~ "a\tb"
  puts "ok2"
else
  puts "no2"
end

re_ml_n = /a\nb/
if re_ml_n =~ "a\nb"
  puts "ok3"
else
  puts "no3"
end

re_ml_r = /a\rb/
if re_ml_r =~ "a\rb"
  puts "ok4"
else
  puts "no4"
end
