class UserSubjectCollection < ActiveRecord::Base
  belongs_to :project
  belongs_to :owner, class_name: "User", foreign_key: "owner_id"
  has_and_belongs_to_many :subjects

  validates_presence_of :owner
end
