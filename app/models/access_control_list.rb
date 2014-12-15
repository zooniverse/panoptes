class AccessControlList < ActiveRecord::Base
  belongs_to :user_group
  belongs_to :resource, polymorphic: true
end
