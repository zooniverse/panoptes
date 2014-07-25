class ProjectContent < ActiveRecord::Base
  include TranslatedContent
  attr_accessible :language, :title, :description, :example_strings, :pages
  validates_presence_of(:title, :description)
end
