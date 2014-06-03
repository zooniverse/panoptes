class UriName < ActiveRecord::Base
  attr_accessible :name
  belongs_to :linked_resource, polymorphic: true
  validates_presence_of :name, :linked_resource
end
