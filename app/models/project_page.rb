class ProjectPage < ActiveRecord::Base
  include LanguageValidation

  has_paper_trail ignore: [:language]

  belongs_to :project

  validates_uniqueness_of :url_key, scope: [:project_id, :language]
end
