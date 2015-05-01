class SubjectQueue < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include BelongsToMany

  DEFAULT_LENGTH = 100
  MINIMUM_LENGTH = 20

  belongs_to :user
  belongs_to :workflow
  belongs_to :subject_set
  belongs_to_many :set_member_subjects

  validates_presence_of :workflow

  can_through_parent :workflow, :update, :destroy, :update_links, :destroy_links

  alias_method :subjects=, :set_member_subjects=

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

  def self.reload(workflow, subject_ids, user: nil, set: nil)
    ues = scoped_to_set(set).find_or_create_by!(user: user, workflow: workflow)
    ues.set_member_subject_ids_will_change!
    ues.set_member_subject_ids = subject_ids
    ues.save!
  end

  def self.enqueue(workflow, subject_ids, user: nil, set: nil)
    ues = scoped_to_set(set).find_or_create_by!(user: user, workflow: workflow)
    ues.set_member_subject_ids_will_change!
    ues.set_member_subject_ids = ues.set_member_subject_ids | Array.wrap(subject_ids)
    ues.save!
  end

  def self.dequeue(workflow, subject_ids, user: nil, set: nil)
    ues = scoped_to_set(set).find_by!(user: user, workflow: workflow)
    ues.set_member_subject_ids_will_change!
    ues.set_member_subject_ids = ues.set_member_subject_ids - (Array.wrap(subject_ids))
    ues.save!
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

  def self.create_for_user(workflow, user, set: nil)
    logged_out_queue = scoped_to_set(set).find_by(workflow: workflow, user: nil)
    return nil unless logged_out_queue
    queue = create(workflow: workflow,
                   user: user,
                   subject_set_id: set,
                   set_member_subject_ids: logged_out_queue.set_member_subject_ids)
    return queue if queue.persisted?
  end

  def below_minimum?
    set_member_subject_ids.length < MINIMUM_LENGTH
  end

  def next_subjects(limit=10)
    set_member_subject_ids[0..limit-1]
  end
end
