class WorkflowContent < ActiveRecord::Base
  include TranslatedContent

  validates_presence_of :strings, :language
end
