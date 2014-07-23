class UserGroup < ActiveRecord::Base
  include Nameable
  include Activatable
  include Owner

  attr_accessible :name, :display_name

  owns :projects, :collections, :subjects

  has_many :users, through: :memberships
  has_many :memberships
  has_many :classifications

  validates :name, presence: true, uniqueness: true

  before_validation :downcase_case_insensitive_fields

  private

  def downcase_case_insensitive_fields
    if name
      self.name = name.downcase
    end
  end
end
