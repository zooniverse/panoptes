class UserSubjectCollection < ActiveRecord::Base
  belongs_to :project
  belongs_to :user
  has_and_belongs_to_many :subjects
end
