class SetMemberSubject < ActiveRecord::Base
  extend RoleControl::ParentalControlled
  
  belongs_to :subject_set, counter_cache: true
  belongs_to :subject
  has_many :classifications

  enum state: [:active, :inactive, :retired]

  validates_presence_of :subject_set, :subject

  can_by_role_through_parent :update, :subject_set
  can_by_role_through_parent :show, :subject_set
  can_by_role_through_parent :destroy, :subject_set
end
