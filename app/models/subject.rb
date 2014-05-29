class Subject < ActiveRecord::Base
  has_and_belongs_to_many :collections
  has_many :subject_groups, through: :grouped_subjects
  has_many :grouped_subjects
end
