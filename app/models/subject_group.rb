# frozen_string_literal: true

class SubjectGroup < ActiveRecord::Base
  belongs_to :project

  has_many :members, class_name: 'SubjectGroupMember', dependent: :destroy
  has_many :subjects, through: :members
  # a 'group' subject to record the grouped view of linked subject locations
  # for use in talk and to collect retirement information about the group
  belongs_to :group_subject, class_name: 'Subject'

  validates :project, presence: true
  validates :members, presence: true
  validates :key, presence: true
  validates :group_subject, presence: true

  # custom member record association ordering
  # to ensure we specify the key order and uniquely identify this subject group
  def members_in_display_order
    members.sort { |m| m.display_order } # rubocop:disable Style/SymbolProc
  end
end
