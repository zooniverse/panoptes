# frozen_string_literal: true

class SubjectGroup < ActiveRecord::Base
  belongs_to :project
  has_many :members, class_name: 'SubjectGroupMember', dependent: :destroy
  has_many :subjects, through: :members

  validates :project, presence: true
  validates :members, presence: true
  validates :key, presence: true

  before_validation :set_key, on: :create

  private

  def set_key
    return if key.present? && members.present?

    self.key = members.map(&:subject_id).join('-')
  end
end
