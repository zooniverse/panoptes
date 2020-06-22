# frozen_string_literal: true

class CachedExport < ActiveRecord::Base
  belongs_to :resource, polymorphic: true

  validates :resource, :data, presence: true
end
