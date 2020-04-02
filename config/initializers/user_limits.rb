# frozen_string_literal: true

module Panoptes
  def self.max_subjects
    ENV.fetch('USER_SUBJECT_LIMIT', 100)
  end
end
