class UserGroup < ActiveRecord::Base
  include Nameable
  include Activatable
  include Owner

  attr_accessible :display_name

  owns :projects, :collections, :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  validates :display_name, presence: true, uniqueness: true

  before_validation :downcase_case_insensitive_fields

  private

  def downcase_case_insensitive_fields
    if display_name
      self.display_name = display_name.downcase
    end
  end
end
