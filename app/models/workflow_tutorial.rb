class WorkflowTutorial < ActiveRecord::Base
  belongs_to :workflow
  belongs_to :tutorial
end
