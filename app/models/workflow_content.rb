class WorkflowContent < ActiveRecord::Base
  include TranslatedContent
  include CacheModelVersion

  validates_presence_of :strings, :language
end
