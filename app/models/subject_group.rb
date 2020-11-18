# frozen_string_literal: true

class SubjectGroup < ActiveRecord::Base
  belongs_to :project

  has_many :members, class_name: 'SubjectGroupMember', dependent: :destroy
  has_many :subjects, through: :members

  validates :project, presence: true
  validates :members, presence: true
  validates :key, presence: true

  before_validation :set_key, on: :create

  # custom member record association ordering
  # to ensure we specify the key order and uniquely identify this subject group
  def members_in_display_order
    members.sort { |m| m.display_order } # rubocop:disable Style/SymbolProc
  end

  private

  def set_key
    return if members.empty?

    self.key = members_in_display_order.map(&:subject_id).join('-')
  end
end
