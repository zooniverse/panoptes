# frozen_string_literal: true

class WorkflowTutorial < ApplicationRecord
  belongs_to :workflow
  belongs_to :tutorial
end
