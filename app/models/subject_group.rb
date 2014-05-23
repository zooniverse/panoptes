class SubjectGroup < ActiveRecord::Base
  belongs_to :project
  has_many :grouped_subjects
  has_many :subjects, through: :grouped_subjects
end
