# frozen_string_literal: true

class CollectionsSubject < ApplicationRecord
  belongs_to :collection, counter_cache: :subjects_count
  belongs_to :subject

  validates_uniqueness_of :subject_id, scope: :collection_id, message: "is already in the collection"
end
