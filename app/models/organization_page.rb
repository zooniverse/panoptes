class OrganizationPage < ActiveRecord::Base
  include Linkable
  include RoleControl::ParentalControlled
  include LanguageValidation

  has_paper_trail ignore: [:language]

  belongs_to :organization

  can_through_parent :organization, :show, :index, :versions, :version

  validates_uniqueness_of :url_key, scope: [:organization_id, :language]

  def self.scope_for(action, user, opts={})
    case action
    when :show, :index
      super
    else
      translatable = Organization.scope_for(:translate, user, opts)
      joins(:organization).merge(translatable)
    end
  end
end
