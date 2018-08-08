class OrganizationPage < ActiveRecord::Base
  include Translatable
  include LanguageValidation

  def self.translatable_attributes
    %i(title content)
  end

  has_paper_trail ignore: [:language]

  belongs_to :organization

  validates_uniqueness_of :url_key, scope: [:organization_id, :language]
end
