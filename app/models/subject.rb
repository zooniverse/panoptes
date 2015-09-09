class Subject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable
  default_scope { eager_load(:locations) }

  has_paper_trail only: [:metadata, :locations]

  belongs_to :project
  belongs_to :uploader, class_name: "User", foreign_key: "upload_user_id"
  has_many :collections_subjects
  has_many :collections, through: :collections_subjects
  has_many :subject_sets, through: :set_member_subjects
  has_many :set_member_subjects
  has_many :locations, -> { where(type: 'subject_location') },
    class_name: "Medium", as: :linked
  has_many :recents, dependent: :destroy

  validates_presence_of :project, :uploader

  can_through_parent :project, :update, :index, :show, :destroy, :update_links,
                     :destroy_links, :versions, :version

  def migrated_subject?
    !!migrated
  end

  def retired_for_workflow?(workflow)
    if workflow && workflow.is_a?(Workflow) && workflow.persisted?
      set_member_subjects.joins(:subject_workflow_counts).where(subject_workflow_counts: {workflow_id: workflow.id})
                         .where(subject_set_id: workflow.subject_sets.pluck(:id))
                         .where.not(subject_workflow_counts: {retired_at: nil})
                         .any?
    else
      false
    end
  end
end
