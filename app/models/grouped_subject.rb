class GroupedSubject < ActiveRecord::Base
  belongs_to :subject_group
  belongs_to :subject
end
