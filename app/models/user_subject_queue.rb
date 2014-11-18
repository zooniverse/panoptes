class UserSubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled
  
  belongs_to :user
  belongs_to :workflow

  validates_presence_of :user, :workflow

  can_through_parent :workflow, :update, :destroy

  delegate :add_subject, to: :set_member_subjects
  delegate :remove_subject, to: :set_member_subjects

  def self.scope_for(action, actor)
    case action
    when :show
      where(workflow: Workflow.scope_for(:update, actor))
    else
      super
    end
  end

  def self.enqueue_subject_for_user(user: nil, workflow: nil, set_member_subject: nil)
    ues = find_or_create_by!(user: user, workflow: workflow)
    ues.add_subject(set_member_subject)
  end

  def self.dequeue_subject_for_user(user: nil, workflow: nil, set_member_subject: nil)
    ues = find_by!(user: user, workflow: workflow)
    ues.remove_subject(set_member_subject)
    ues.destroy if ues.set_member_subject_ids.empty?
  end

  def self.is_subject_queued?(user: nil, workflow: nil, set_member_subject: nil)
    where.any(set_member_subject_ids: set_member_subject.id)
      .exists?(user: user, workflow: workflow)
  end
  
  def sample_subjects(limit=10)
    set_member_subject_ids.sample(limit)
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
