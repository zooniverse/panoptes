class SetMemberSubject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable
  
  belongs_to :subject_set, counter_cache: true, touch: true
  belongs_to :subject

  enum state: [:active, :inactive, :retired]

  validates_presence_of :subject_set, :subject

  can_through_parent :subject_set, :update, :show, :destroy, :index, :update_links,
                     :destroy_links

  def self.by_subject_workflow(subject, workflow)
    joins(:subject_set)
      .where(subject_id: subject, subject_sets: { workflow_id: workflow })
  end

  def retire?
    subject_set.retire_member?(self)
  end
end
