class ProjectContent < ActiveRecord::Base
  has_paper_trail skip: [:language]

  belongs_to :project

  validates :language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
  validates_presence_of :task_strings, :title, :description
end
