class Project < ActiveRecord::Base
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"
  has_many :workflows
  has_many :subject_groups

  validates_presence_of :owner
end
