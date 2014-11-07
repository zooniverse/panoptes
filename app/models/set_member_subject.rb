class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable
  
  belongs_to :subject_set, counter_cache: true
  belongs_to :subject
  has_many :classifications

  attr_accessible :state, :priority

  enum state: [:active, :inactive, :retired]

  validates_presence_of :subject_set, :subject

  can_through_parent :subject_set, :update, :show, :destroy
end
