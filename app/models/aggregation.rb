class Aggregation < ActiveRecord::Base
  include RoleControl::ParentalControlled

  belongs_to :workflow
  belongs_to :subject

  has_paper_trail only: [:aggregation]

  can_through_parent :workflow, :update, :destroy, :update_links,
                     :destroy_links, :versions, :version

  validates_presence_of :workflow, :subject, :aggregation
  validates_uniqueness_of :subject_id, scope: :workflow_id
  validate :aggregation, :workflow_version_present

  def self.scope_for(action, user, opts={})
    case
    when action == :index && opts[:workflow_id]
      joins(:workflow).where(workflow_id: opts[:workflow_id])
    when (action == :show || action == :index) && !user.is_admin?
      joins(:workflow).merge(Workflow.scope_for(:update, user, opts))
    else
      super
    end
  end

  private

  def workflow_version_present
    wv_key = :workflow_version
    if aggregation && !aggregation.symbolize_keys.has_key?(wv_key)
      errors.add(:aggregation, "must have #{wv_key} metadata")
    end
  end
end
