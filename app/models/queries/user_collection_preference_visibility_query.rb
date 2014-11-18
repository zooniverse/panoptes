class UserCollectionPreferenceVisibilityQuery < VisibilityQuery
  private

  def queries
    [where_user, where_collection]
  end

  def all_bind_values
    collection_scope.bind_values
  end

  def union_table
    Arel::Table.new(:user_collection_preferences)
  end

  def collection_scope
    @collection_scope ||= Collection.scope_for(:update, actor).select(:id)
  end

  def where_collection
    @where_collection ||= parent.where(arel_table[:collection_id].in(collection_scope.arel))
  end
end
