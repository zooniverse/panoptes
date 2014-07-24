class OwnerName < ActiveRecord::Base
  attr_accessible :name, :resource
  belongs_to :resource, polymorphic: true

  validates :name, presence: true, uniqueness: true
  validates :resource, presence: true

  before_validation :downcase_case_insensitive_fields

  private

  def downcase_case_insensitive_fields
    if name
      self.name = name.downcase
    end
  end
end
