class UserSubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled
  
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  can_through_parent :workflow, :update, :destroy, :update_links, :destroy_links

  delegate :add_subjects, to: :subjects
  delegate :remove_subjects, to: :subjects

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
    ues.add_subjects(subject)
  end

  def self.dequeue_subjects_for_user(user: nil, workflow: nil, subject_ids: nil)
    ues = find_by!(user: user, workflow: workflow)
    ues.remove_subjects(subject_ids)
    ues.destroy if ues.subject_ids.empty?
  end

  def self.are_subjects_queued?(user: nil, workflow: nil, subject_ids: nil)
    where.overlap(subject_ids: subject_ids)
      .exists?(user: user, workflow: workflow)
  end
  
  def next_subjects(limit=10)
    subject_ids[0,limit]
  end
  
  def subjects=(subjects)
    subject_ids_will_change!
    self.subject_ids = subjects.map(&:id)
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
