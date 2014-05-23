class Project < ActiveRecord::Base
  belongs_to :user
  has_many :workflow
  has_many :subject_groups
end
