# When the same ivar is registered on both a child class and a
# parent, the C struct embeds the parent's field at the parent's
# recorded type (`emit_class_fields` skips own copies that are also
# in the parent chain). `cls_ivar_type` used to return the child's
# own-table entry — letting downstream emit sites disagree with
# the actual struct field type.

class Parent
  def initialize
    @x = 0
    @x = "s"      # heterogeneous int+string → @x widens to poly
  end
end

class Child < Parent
  def initialize
    super
    @x = 7        # write through the inherited (poly) slot
  end
  def read_x
    @x
  end
end

c = Child.new
# Reading back via a Child-defined method that emits `self->iv_x`.
# Without the fix, cls_ivar_type(Child, "@x") returned the int from
# Child's own table; the struct field is sp_RbVal (Parent's poly);
# the read miscompiled / yielded a garbage int. With the fix the
# emit goes through the poly read path and unboxes correctly.
v = c.read_x
puts v        # 7
