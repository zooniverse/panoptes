class SubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled

  belongs_to :user
  belongs_to :workflow
  belongs_to :subject_set

  validates_presence_of :workflow

  can_through_parent :workflow, :update, :destroy, :update_links, :destroy_links

  delegate :add_set_member_subjects, to: :subjects
  delegate :remove_set_member_subjects, to: :subjects

  def self.scope_for(action, groups, opts={})
    case action
    when :show, :index
      where(workflow: Workflow.scope_for(:update, groups, opts))
    else
      super
    end
  end

  def self.enqueue_subject_for_user(user: nil, workflow: nil, subject: nil)
    ues = find_or_create_by!(user: user, workflow: workflow)
    ues.add_set_member_subjects(subject)
  end
  
  def self.enqueue_subjects(workflow, subject_ids, user: nil, set: nil)
    ues = find_or_create_by!(user: user, workflow: workflow, subject_set_id: set)
    ues.add_set_member_subjects(subject_ids)
  end

  def self.dequeue_subjects_for_user(user: nil, workflow: nil, subject_ids: nil)
    ues = find_by!(user: user, workflow: workflow)
    ues.remove_set_member_subjects(subject_ids)
    ues.destroy if ues.set_member_subject_ids.empty?
  end

  def self.are_subjects_queued?(user: nil, workflow: nil, subject_ids: nil)
    where.overlap(set_member_subject_ids: subject_ids)
      .exists?(user: user, workflow: workflow)
  end

  def next_subjects(limit=10)
    set_member_subject_ids[0..limit-1]
  end

  def subjects=(subjects)
    set_member_subject_ids_will_change!
    self.set_member_subject_ids = subjects.map(&:id)
    save! && reload if persisted?
    subjects
  end

  def reload
    super
    @subject_relation ||= SubjectRelation.new(self)
    self
  end

  def subjects
    @subject_relation ||= SubjectRelation.new(self)
  end
end
