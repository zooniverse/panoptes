class Membership < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  scope :active, -> { where(state: states[:active]) }
  scope :identity, -> { active.where(identity: true).where("memberships.roles = '{group_admin}'") }
  scope :not_identity, -> { where(identity: false) }

  validates_presence_of :user, unless: :identity
  validates_associated :user_group
  validates_presence_of :state, :user_group
  validates_uniqueness_of :user_group, scope: :user

  def disable!
    inactive!
  end

  def enable!
    active!
  end

  def group_admin?
    roles.include?("group_admin")
  end
end
