class TaggedResource < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  belongs_to :tag, counter_cache: true

  validates_presence_of :resource, :tag
end
