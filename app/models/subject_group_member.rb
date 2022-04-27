# frozen_string_literal: true

class SubjectGroupMember < ActiveRecord::Base
  belongs_to :subject
  belongs_to :subject_group
  has_one :project, through: :subject_group

  validates :display_order, presence: true

  validates :subject, presence: true
  validates :subject_group, presence: true
end
