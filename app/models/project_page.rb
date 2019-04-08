class ProjectPage < ActiveRecord::Base
  include Translatable
  include LanguageValidation
  include Versioning

  has_many :project_page_versions, dependent: :destroy
  versioned association: :project_page_versions, attributes: %w(title content url_key)

  belongs_to :project

  validates_uniqueness_of :url_key, scope: [:project_id, :language]

  def self.translatable_attributes
    %i(title content)
  end
end
