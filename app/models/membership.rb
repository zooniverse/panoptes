class Membership < ActiveRecord::Base
  include RoleControl::RoleModel
  
  attr_accessible :state
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  roles_for :user, :user_group, valid_roles: [:group_admin,
                                              :project_editor,
                                              :collection_editor,
                                              :group_member]

  validates_presence_of :user, :user_group, :state

  def disable!
    inactive!
  end

  def enable!
    active!
  end
end
