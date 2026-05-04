# `obj.attr = v` codegen emitted `slot = arg0` regardless of slot
# type. When the slot is poly (sp_RbVal — widened by heterogeneous
# writes) and the rhs is typed (int / string / obj_X / ...), C
# rejects the assignment as a struct-from-scalar/pointer mismatch.

class Bag
  attr_accessor :item
  def initialize
    @item = "tag"     # string first…
    @item = 5         # …then int — slot widens to poly
  end
end

class Caller
  def stuff(bag)
    bag.item = 99     # statement-form attr-writer on poly slot
    bag.item
  end
end

b = Bag.new
puts Caller.new.stuff(b)   # 99
puts (b.item = 7)          # 7  (expression-form; `=` returns rhs)
puts b.item                # 7
