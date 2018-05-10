class SubjectSetImport < ActiveRecord::Base
  belongs_to :subject_set
  belongs_to :user
end
