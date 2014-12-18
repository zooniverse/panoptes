class UserProjectPreference < ActiveRecord::Base
  belongs_to :user, dependent: :destroy
  belongs_to :project, dependent: :destroy

  validates_presence_of :user, :project
end
