# Issue #208: a class method (`def self.<name>`) defined on the
# parent class must dispatch when called via the subclass. Spinel
# previously emitted "cannot resolve call to '<method>' on
# class_<Subclass>" and substituted 0 because cls_cmethod lookup
# only walked the immediate class.

class Base
  def self.all
    [42, 1, 7]
  end
end

# Single level
class Leaf < Base; end
puts Leaf.all.size                   # 3

# Multi level
class Mid < Base; end
class Deep < Mid; end
puts Mid.all.size                    # 3
puts Deep.all.size                   # 3

# Direct call on the defining class still works
puts Base.all.size                   # 3
