class ProjectContent < ActiveRecord::Base
  has_paper_trail skip: [:language]

  attr_accessible :language, :title, :description, :example_strings

  belongs_to :project

  validates :language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}
  validates_presence_of :title, :description
end
