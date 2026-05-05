# Issue #247: when two writers in different methods of the same class
# disagree on the value type, spinel used to narrow the slot to
# whichever writer's update_ivar_type call ran last — and the loser's
# emit site silently miscompiled. Here writer 1 in initialize assigns
# an int (via SymIntHash#[]) and writer 2 in write_any assigns a
# string param; the slot must widen to poly so both store cleanly.

class C
  def initialize(h)
    @id = h[:id]
  end

  def id; @id; end

  def write_any(value)
    @id = value
  end
end

c = C.new({id: 42})
c.write_any("string")
puts c.id

# Ensure the int-writer side still works when we don't re-write to a
# different type — the slot stays as observed.
class D
  def initialize(h)
    @v = h[:v]
  end
  def v; @v; end
end

d = D.new({v: 7})
puts d.v
