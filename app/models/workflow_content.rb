class WorkflowContent < ActiveRecord::Base
  include TranslatedContent
  attr_accessible :language, :strings
end
