class OrganizationPage < ActiveRecord::Base
  include Translatable
  include LanguageValidation
  include Versioning

  belongs_to :organization
  has_many :organization_page_versions, dependent: :destroy

  versioned association: :organization_page_versions, attributes: %w(title content url_key)

  validates_uniqueness_of :url_key, scope: [:organization_id, :language]

  def self.translatable_attributes
    %i(title content)
  end
end
