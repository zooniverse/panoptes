class Project < ActiveRecord::Base
  include Ownable

  has_many :workflows
  has_many :subject_sets

  validates_presence_of :owner
end
