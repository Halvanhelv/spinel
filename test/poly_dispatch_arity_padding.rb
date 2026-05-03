# Poly dispatch over user classes whose `m` definitions have
# different arities — Switch#toggle takes 0 args; Knob#toggle takes
# one positional default. Without per-arm padding, the C compiler
# rejects the dispatch table with "too few arguments to function
# 'sp_Knob_toggle'" (the dispatch arms have one fixed call shape
# but the candidate methods have different arities).

class Switch
  def initialize
    @v = 1
  end
  def toggle
    @v = 0
  end
  attr_reader :v
end

class Knob
  def toggle(soft = true)
    0
  end
end

class Box
  def initialize
    @items = [Switch.new, Switch.new]   # poly-typed; .toggle dispatch
                                        # over every class with `toggle`
  end
  attr_reader :items
end

b = Box.new
b.items[0].toggle
b.items[1].toggle
puts b.items[0].v   # 0
puts b.items[1].v   # 0
