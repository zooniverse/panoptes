class SubjectWorkflowStatus < ActiveRecord::Base
  self.table_name = 'subject_workflow_counts'

  include RoleControl::ParentalControlled

  belongs_to :subject
  belongs_to :workflow

  enum retirement_reason:
    [ :classification_count, :flagged, :nothing_here, :consensus, :other, :human ]

  scope :retired, -> { where.not(retired_at: nil) }

  validates :subject, presence: true, uniqueness: {scope: :workflow_id}
  validates :workflow, presence: true

  delegate :set_member_subjects, to: :subject
  delegate :project, to: :workflow

  can_through_parent :workflow, :show, :index

  # this is an optimized query to access the subject_id index on this table.
  # It uses an IN query with a CTE to create a subselect to access
  # the subject_id index as simple Joins do not use the index on this table
  def self.by_set(subject_set_ids)
    # create the CTE for reuse, e.g.
    # sws_by_set AS (
    #   SELECT set_member_subjects.subject_id
    #   FROM set_member_subjects
    #   WHERE set_member_subjects.subject_set_id = 1
    # )
    cte_table = Arel::Table.new(:sws_by_set)
    smses_arel = SetMemberSubject.arel_table
    composed_cte = Arel::Nodes::As.new(
      cte_table,
      smses_arel.where(
        smses_arel[:subject_set_id].in(subject_set_ids)
      ).project(smses_arel[:subject_id])
    )

    # create the select from CTE, e.g
    # SELECT subject_id FROM sws_by_set
    select_manager = Arel::SelectManager.new(cte_table.engine)
    select_manager.project(:subject_id)
    select_manager.from("sws_by_set")

    # create the where in clause matching the select from CTE, e.g.
    # subject_workflow_counts.subject_id IN (SELECT subject_id FROM sws_by_set)
    subquery_where = arel_table[:subject_id].in(select_manager)

    # put it all together and combine the in clause with the CTE, e.g.
    # WITH sws_by_set AS (
    #   SELECT set_member_subjects.subject_id
    #   FROM set_member_subjects
    #   WHERE set_member_subjects.subject_set_id = 1
    # )
    # SELECT subject_workflow_counts.*
    # FROM subject_workflow_counts
    # WHERE subject_workflow_counts.subject_id
    # IN (SELECT subject_id FROM sws_by_set)
    where(subquery_where).with(composed_cte)
  end

  def self.by_subject(subject_id)
    where(subject_id: subject_id)
  end

  def self.by_workflow(workflow_id)
    where(workflow_id: workflow_id)
  end

  def self.by_subject_workflow(subject_id, workflow_id)
    where(subject_id: subject_id, workflow_id: workflow_id).first
  end

  def retire?
    !retired? && workflow.retirement_scheme.retire?(self)
  end

  def retire!(reason=nil)
    unless retired?
      update!(retirement_reason: reason, retired_at: Time.zone.now)
    end
  end

  def retired?
    retired_at.present?
  end

  def set_member_subject_ids
    set_member_subjects.pluck(:id)
  end
end
