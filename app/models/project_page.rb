class ProjectPage < ActiveRecord::Base
  include TranslatedContent

  def self.translated_for
    "project"
  end

  validates_uniqueness_of :url_key, scope: [:project_id, :language]
end
