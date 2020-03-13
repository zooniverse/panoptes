class SubjectGroup < ActiveRecord::Base
  belongs_to :project
  has_and_belongs_to_many :subjects

  validates :project, presence: true
  validates :subjects, presence: true
end
