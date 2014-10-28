class WorkflowContent < ActiveRecord::Base
  include TranslatedContent

  attr_accessible :language, :strings

  validates_presence_of :strings, :language
end
