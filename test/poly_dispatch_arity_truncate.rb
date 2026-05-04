# Poly-dispatch arms must match each candidate method's *fixed* C
# arity. The padding side (target takes more params than the call
# supplied — defaults fill the extras) was already in place. The
# truncate side is the complement: when a candidate class's method
# accepts *fewer* params than the call supplied, that arm has to
# drop the surplus to compile, even though the runtime cls_id check
# would skip it for a non-matching receiver.

class Heater
  def initialize
    @v = 0
  end
  def write(addr, data)
    @v = addr + data
  end
  attr_reader :v
end

class Buzzer
  def initialize
    @v = 0
  end
  def write(addr)        # one fewer arg than Heater#write
    @v = addr
  end
  attr_reader :v
end

class Box
  def initialize
    @poly = nil
    @poly = "x"
    @poly = Heater.new   # widen to poly via heterogeneous writes
  end

  attr_reader :poly

  def call_write(addr, data)
    @poly.write(addr, data)   # poly recv → arms over Heater + Buzzer
  end
end

b = Box.new
b.call_write(7, 5)
puts b.poly.v   # 12  (Heater: addr + data)
