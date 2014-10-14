class VisibilityQuery
  include UnionQueryBuilder
  
  attr_reader :actor, :parent
  
  def initialize(actor, parent)
    @actor, @parent = actor, parent
  end
  
  def build(as_admin)
    return @parent.all if actor.is_admin? && as_admin
    super()
  end
  
  def arel_table
    parent.arel_table
  end
end
