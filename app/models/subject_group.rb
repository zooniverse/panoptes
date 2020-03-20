# frozen_string_literal: true

class SubjectGroup < ActiveRecord::Base
  belongs_to :project
  has_many :members, class_name: 'SubjectGroupMember', dependent: :destroy
  has_many :subjects, through: :members

  validates :project, presence: true
  validates :subjects, presence: true
end
