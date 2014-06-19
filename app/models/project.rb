class Project < ActiveRecord::Base
  include Ownable
  include SubjectCounts
  include Activatable
  include Visibility

  has_many :workflows
  has_many :subject_sets
  has_many :classifications
  has_many :subjects
  has_many :project_contents

  visibility_level :dev, :collaborator
  visibility_level :beta, :collaborator, :beta_tester, :scientist, :translator
  visibility_level :private, :collaborator, :scientist, :invited

  validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}

  def content_for(language)
    project_contents.where(language: language).first
  end

  def available_languages
    project_contents.select('language').map(&:language)
  end
end
