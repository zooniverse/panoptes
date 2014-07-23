class WorkflowContent < ActiveRecord::Base
  include TranslatedContent
  attr_accessible :langauge, :strings
end
