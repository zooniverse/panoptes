class BelongsToManyBuilder < ActiveRecord::Associations::Builder::CollectionAssociation
  def macro; :belongs_to_many; end
end
