class OrganizationPage < ActiveRecord::Base
  include RoleControl::PunditInterop
  include Linkable
  include LanguageValidation

  has_paper_trail ignore: [:language]

  belongs_to :organization

  validates_uniqueness_of :url_key, scope: [:organization_id, :language]
end
