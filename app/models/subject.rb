class Subject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable
  default_scope { eager_load(:locations) }

  has_paper_trail only: [:metadata, :locations]

  belongs_to :project
  belongs_to :uploader, class_name: "User", foreign_key: "upload_user_id", touch: true,
    counter_cache: :uploaded_subjects_count
  has_many :collections_subjects
  has_many :collections, through: :collections_subjects
  has_many :subject_sets, through: :set_member_subjects
  has_many :set_member_subjects
  has_many :locations, -> { where(type: 'subject_location') }, class_name: "Medium", as: :linked
  has_many :recents, dependent: :destroy

  validates_presence_of :project, :uploader

  can_through_parent :project, :update, :index, :show, :destroy, :update_links,
                     :destroy_links, :versions, :version

  def migrated_subject?
    !!migrated
  end

  def retired_for_workflow?(workflow)
    retired = false
    if workflow && workflow.is_a?(Workflow) && workflow.persisted?
      sms = workflow.set_member_subjects.where(subject_id: self.id).first
      if sms && swc = SubjectWorkflowCount.find_by(workflow_id: workflow.id, set_member_subject_id: sms.id)
        retired = swc.retired?
      end
    end
    retired
  end
end
