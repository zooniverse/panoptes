class OrganizationContent < ActiveRecord::Base
  include TranslatedContent

  validates_presence_of :title, :description, :language
  validates_length_of :title, maximum: 255
  validates_length_of :description, maximum: 300
  validates_length_of :introduction, maximum: 5000
  validates_length_of :announcement, maximum: 5000
end
