class AccessControlList < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :resource, polymorphic: true

  validates_presence_of :user_group
  validates_uniqueness_of :user_group, scope: [:resource_id, :resource_type], message: ". Roles have already been set for this user or group"
end
