class UserGroupMembership < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :user
  enum state: [:active, :invited, :inactive]

  validates_presence_of :user, :user_group, :state
end
