class UserCollectionPreference < ActiveRecord::Base
  belongs_to :user, dependent: :destroy
  belongs_to :collection, dependent: :destroy

  validates_presence_of :user, :collection
end
