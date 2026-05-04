# `a && b` codegen used to lower to raw C `a && b` regardless of
# operand type. When either operand is `sp_RbVal` (poly), C rejects
# `&&` between a struct and an int. Wrap poly operands with
# `sp_poly_truthy`.

class Holder
  def initialize
    @poly = "x"   # string first…
    @poly = 42    # …then int — slot widens to poly
    @counter = 0
  end

  attr_reader :poly, :counter

  def chain
    if @poly && @counter == 0
      @counter = 1
    end
    @counter
  end
end

h = Holder.new
puts h.chain    # 1
