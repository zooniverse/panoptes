class UriName < ActiveRecord::Base
  belongs_to :resource, polymorphic: true
  validates_presence_of :name
end
