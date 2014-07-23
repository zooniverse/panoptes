class ProjectContent < ActiveRecord::Base
  include TranslatedContent
  attr_accessible :language, :title, :description, :example_strings, :pages
  translated_fields :title, :description, :example_strings, :pages
end
