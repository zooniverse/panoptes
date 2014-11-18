class OwnerName < ActiveRecord::Base
  belongs_to :resource, polymorphic: true

  validates :name, presence: true, uniqueness: true
  validates :resource, presence: true

  before_validation :clean_name_field

  private

  def clean_name_field
    if name
      self.name = StringConverter.downcase_and_replace_spaces(name)
    end
  end
end
