class ProjectContent < ActiveRecord::Base
  include TranslatedContent
 
  validates_presence_of :title, :description, :language
end
