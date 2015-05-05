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

  def self.reload(workflow, sms_ids, user: nil, set: nil)
    ues = scoped_to_set(set).find_or_create_by!(user: user, workflow: workflow)
    ues.set_member_subject_ids_will_change!
    ues.set_member_subject_ids = sms_ids
    ues.save!
  end

  def self.enqueue(workflow, sms_ids, user: nil, set: nil)
    return if sms_ids.blank?
    ues = scoped_to_set(set).find_or_create_by!(user: user, workflow: workflow)
    enqueue_update(where(id: ues.id), sms_ids)
  end

  def self.dequeue(workflow, sms_ids, user: nil, set: nil)
    return if sms_ids.blank?
    ues = scoped_to_set(set).where(user: user, workflow: workflow)
    dequeue_update(ues, sms_ids)
  end

  def self.enqueue_for_all(workflow, sms_ids)
    return if sms_ids.blank?
    sms_ids = Array.wrap(sms_ids)
    enqueue_update(where(workflow: workflow), sms_ids)
  end

  def self.dequeue_for_all(workflow, sms_id)
    return if sms_id.blank?
    dequeue_update(where(workflow: workflow), sms_id)
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

  def self.dequeue_update(query, sms_ids)
    dequeue_sql = "set_member_subject_ids = ARRAY(SELECT unnest(set_member_subject_ids) except SELECT unnest(array[?]))"
    query.update_all([dequeue_sql, sms_ids])
  end

  def self.enqueue_update(query, sms_ids)
    query.update_all(["set_member_subject_ids = array_cat(set_member_subject_ids, array[?])", sms_ids])
  end

  def below_minimum?
    set_member_subject_ids.length < MINIMUM_LENGTH
  end

  def next_subjects(limit=10)
    if user_id
      set_member_subject_ids[0..limit-1]
    else
      set_member_subject_ids.sample(limit)
    end
  end
end
