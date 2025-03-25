# frozen_string_literal: true

class ProjectVersion < ApplicationRecord
  belongs_to :project
end
