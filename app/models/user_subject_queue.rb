class UserSubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled
  
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  can_through_parent :workflow, :update, :destroy, :update_links, :destroy_links

  delegate :add_subjects, to: :set_member_subjects
  delegate :remove_subjects, to: :set_member_subjects

  def self.scope_for(action, groups, opts={})
    case action
    when :show, :index
      where(workflow: Workflow.scope_for(:update, groups, opts))
    else
      super
    end
  end

  def self.enqueue_subject_for_user(user: nil, workflow: nil, set_member_subject: nil)
    ues = find_or_create_by!(user: user, workflow: workflow)
    ues.add_subjects(set_member_subject)
  end

  def self.dequeue_subjects_for_user(user: nil, workflow: nil, set_member_subject_ids: nil)
    ues = find_by!(user: user, workflow: workflow)
    ues.remove_subjects(set_member_subject_ids)
    ues.destroy if ues.set_member_subject_ids.empty?
  end

  def self.are_subjects_queued?(user: nil, workflow: nil, set_member_subject_ids: nil)
    where.overlap(set_member_subject_ids: set_member_subject_ids)
      .exists?(user: user, workflow: workflow)
  end
  
  def next_subjects(limit=10)
    set_member_subject_ids[0,limit]
  end
  
  def set_member_subjects=(subjects)
    set_member_subject_ids_will_change!
    self.set_member_subject_ids = subjects.map(&:id)
    save! && reload if persisted?
    subjects
  end

  def reload
    super
    @set_member_subject_relation ||= SetMemberSubjectRelation.new(self)
    self
  end

  def set_member_subjects
    @set_member_subject_relation ||= SetMemberSubjectRelation.new(self)
  end
end
