class ProjectPage < ActiveRecord::Base
  include Translatable
  include LanguageValidation

  has_paper_trail ignore: [:language]

  belongs_to :project

  validates_uniqueness_of :url_key, scope: [:project_id, :language]

  def self.translatable_attributes
    %i(title content)
  end
end
