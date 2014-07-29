class UserGroup < ActiveRecord::Base
  include Nameable
  include Activatable
  include ControlControl::Resource
  include ControlControl::Actor
  include ControlControl::Owner
  include ControlControl::ActAs
  include RoleControl::Controlled

  attr_accessible :name, :display_name

  owns :projects
  owns :collections
  owns :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  validates :name, presence: true, uniqueness: true

  before_validation :downcase_case_insensitive_fields

  private

  def downcase_case_insensitive_fields
    if name
      self.name = name.downcase
    end
  end
end
