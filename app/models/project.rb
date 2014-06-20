class Project < ActiveRecord::Base
  include Ownable
  include SubjectCounts
  include Activatable
  include Visibility

  attr_accessible :name, :display_name, :owner, :primary_language, :project_contents

  has_many :workflows
  has_many :subject_sets
  has_many :classifications
  has_many :subjects
  has_many :project_contents

  visibility_level :dev, :collaborator
  visibility_level :beta, :collaborator, :beta_tester, :scientist, :translator
  visibility_level :private, :collaborator, :scientist, :invited

  validates :primary_language, format: {with: /\A[a-z]{2}(\z|-[A-z]{2})/}

  def content_for(languages, fields)
    language = best_match_for(languages)
    project_contents.select(*fields).where(language: language).first
  end

  def available_languages
    project_contents.select('language').map(&:language).map(&:downcase)
  end

  private

  def best_match_for(languages)
    languages = languages.flat_map do |lang|
      if lang.length == 2
        lang
      else
        [lang, lang.split('-').first]
      end
    end
    (languages & available_languages).first || primary_language
  end
end
