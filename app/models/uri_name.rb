class UriName < ActiveRecord::Base
  attr_accessible :name, :resource
  belongs_to :resource, polymorphic: true
  validates_presence_of :name, :resource
end
