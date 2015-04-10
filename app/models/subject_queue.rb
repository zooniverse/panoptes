class SubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled

  belongs_to :user
  belongs_to :workflow
  belongs_to :subject_set

  validates_presence_of :workflow

  can_through_parent :workflow, :update, :destroy, :update_links, :destroy_links

  delegate :add_set_member_subjects, to: :subjects
  delegate :remove_set_member_subjects, to: :subjects

  def self.scoped_to_set(set)
    set ? where(subject_set_id: set) : all
  end

  def self.scope_for(action, groups, opts={})
    case action
    when :show, :index
      where(workflow: Workflow.scope_for(:update, groups, opts))
    else
      super
    end
  end

  def self.enqueue(workflow, subject_ids, user: nil, set: nil)
    ues = scoped_to_set(set).find_or_create_by!(user: user, workflow: workflow)
    ues.add_set_member_subjects(Array.wrap(subject_ids))
  end

  def self.dequeue(workflow, subject_ids, user: nil, set: nil)
    ues = scoped_to_set(set).find_by!(user: user, workflow: workflow)
    ues.remove_set_member_subjects(subject_ids)
    ues.destroy if ues.set_member_subject_ids.empty?
  end

  def self.enqueue_for_all(workflow, subject_ids)
    subject_ids = Array.wrap(subject_ids)
    raise ArgumentError, "must be an integer" if subject_ids.index{ |sub| !sub.is_a?(Fixnum) }
    where(workflow: workflow)
      .update_all("set_member_subject_ids = array_cat(set_member_subject_ids, ARRAY[#{subject_ids.join(",")}])")
  end

  def self.dequeue_for_all(workflow, subject_id)
    where(workflow: workflow)
      .update_all(["set_member_subject_ids = array_remove(set_member_subject_ids, ?)",
                  subject_id])
  end

  def self.subjects_queued?(workflow, subject_ids, user: nil)
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
