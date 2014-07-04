class UserGroup < ActiveRecord::Base
  include Activatable
  include Owner

  attr_accessible :display_name

  owns :projects, :collections, :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  validates :display_name, presence: true
  validate :unique_display_name

  private

  def unique_display_name
    if errors.empty? && !UniqueRoutableName.new(self).unique?
      errors.add(:display_name, "is already taken")
    end
  end
end
