# Issue #286: a parent class's instance method param needs to widen
# from subclass call sites too, not just from same-class call sites.
# Previously scan_new_calls's bare-call branch only checked
# `find_method_idx` (top-level methods); a `bar(arg)` inside a
# subclass that resolves through inheritance to the parent's `bar`
# would leave the parent's param frozen at its initial type and
# fail to type-check at the call site.
#
# Fix: when the bare call is inside a class method body
# (@current_class_idx >= 0), walk up the inheritance chain via
# find_method_owner to locate the ancestor that defines the
# method, then widen *that* class's @cls_meth_ptypes from the
# call-site arg types — same shape the recv >= 0 branch already
# uses for explicit-receiver calls.

class T
  def assert_eq(expected, actual)
    if expected == actual
      puts "ok"
    else
      puts "ng"
    end
  end
end

class Article
  def initialize
    @id = 0
  end
  def write_str(s)
    @id = s   # widens @id to poly (#247)
  end
  def id
    @id
  end
end

class T2 < T
  def test_it
    a = Article.new
    a.write_str("hi")
    # Bare call to inherited assert_eq, passing a poly value (a.id).
    # Without the fix, `T#assert_eq`'s `actual` param stays at int
    # and the call site emits a type-mismatched store.
    assert_eq("hi", a.id)
  end
end

T2.new.test_it
