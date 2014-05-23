class Classification < ActiveRecord::Base
  belongs_to :grouped_subject
  belongs_to :project
  belongs_to :user
  belongs_to :workflow
end
