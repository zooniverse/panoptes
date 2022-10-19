class TaggedResource < ApplicationRecord
  belongs_to :resource, polymorphic: true
  belongs_to :tag, counter_cache: true, dependent: :destroy
end
