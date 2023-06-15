# frozen_string_literal: true

class UserGroup < ApplicationRecord
  include Activatable
  include PgSearch::Model

  has_many :memberships, dependent: :destroy
  has_many :active_memberships, -> { active.not_identity }, class_name: "Membership"
  has_one  :identity_membership, -> { identity }, class_name: "Membership"
  has_many :users, through: :memberships
  has_many :classifications, dependent: :restrict_with_exception
  has_many :access_control_lists, dependent: :destroy

  has_many :owned_resources, -> { where("roles && '{owner}'") },
           class_name: "AccessControlList"

  has_many :projects, through: :owned_resources, source: :resource,
           source_type: "Project"
  has_many :collections, through: :owned_resources, source: :resource,
           source_type: "Collection"

  ## 
  # Stats_Visibility Levels (Used for ERAS stats service)
  # private_agg_only (default): Only members of a user group can view aggregate stats. However, individual stats only viewable by admins of the user group
  #
  # private_show_agg_and_ind: Only members of a user group can view aggregate stats. Individual stats is viewable by BOTH members and admins of the user group.
  # 
  # public_agg_only: Anyone can view aggregate stats of the user group. However, only admins can view individual stats.
  #
  # public_show_all: Anyone can view aggregate stats of the user group and can view individual stats of the user group. 
  ##
  enum stats_visibility: {
    private_agg_only: 0,
    private_show_agg_and_ind: 1,
    public_agg_only: 2,
    public_show_all: 3
  }

  validates :display_name, presence: true
  validates :name, presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: User::USER_LOGIN_REGEX }

  before_validation :default_display_name, on: [:create, :update]
  before_validation :default_join_token, on: [:create]

  scope :public_groups, -> { where(private: false) }

  pg_search_scope :search_name,
    against: :display_name,
    using: :trigram,
    ranked_by: ":trigram"

  def self.roles_allowed_to_access(action, klass=nil)
    roles = case action
            when :show, :index
              [:group_admin, :group_member]
            else
              [:group_admin]
            end
    roles.push :"#{klass.name.underscore}_editor" if klass
    roles
  end

  def owns?(resource)
    owned_resources.exists?(resource_id: resource.id,
                            resource_type: resource.class.to_s)
  end

  def has_admin?(user)
    membership_for_user(user)&.group_admin?
  end

  def membership_for_user(user)
    memberships.find_by(user_id: user.id)
  end

  def identity?
    !!identity_membership
  end

  def verify_join_token(token_to_verify)
    join_token.present? && join_token == token_to_verify
  end

  private

  def default_display_name
    self.display_name ||= name
  end

  def default_join_token
    self.join_token ||= SecureRandom.hex(8)
  end
end
