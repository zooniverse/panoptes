# frozen_string_literal: true

class Organization < ApplicationRecord
  include RoleControl::Owned
  include Activatable
  include SluggedName
  include Translatable
  include Versioning

  has_many :projects
  has_many :acls, class_name: "AccessControlList", as: :resource, dependent: :destroy
  has_one :avatar, -> { where(type: "organization_avatar") }, class_name: "Medium", as: :linked
  has_one :background, -> { where(type: "organization_background") }, class_name: "Medium", as: :linked
  has_many :organization_roles, ->{ where.not("access_control_lists.roles = '{}'") }, class_name: "AccessControlList", as: :resource
  has_many :organization_versions, dependent: :destroy
  has_many :pages, class_name: "OrganizationPage", dependent: :destroy
  has_many :attached_images, -> { where(type: "organization_attached_image") }, class_name: "Medium",
    as: :linked
  has_many :tagged_resources, as: :resource
  has_many :tags, through: :tagged_resources

  versioned association: :organization_versions, attributes: %w(display_name description introduction urls url_labels announcement)

  validates :primary_language, format: {with: LanguageValidation.lang_regex}

  alias_attribute :title, :display_name

  def self.translatable_attributes
    %i(display_name title description introduction announcement url_labels)
  end

  def retired_subjects_count
    projects.joins(:active_workflows).sum("workflows.retired_set_member_subjects_count")
  end
end
