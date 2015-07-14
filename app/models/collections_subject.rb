class CollectionsSubject < ActiveRecord::Base
  belongs_to :collection
  belongs_to :subject

  validates_uniqueness_of :subject_id, scope: :collection_id, message: "is already in the collection"
end
