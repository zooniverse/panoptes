class Subject < ActiveRecord::Base
  include RoleControl::ParentalControlled
  include Linkable

  has_paper_trail only: [:metadata, :locations]

  belongs_to :project
  has_and_belongs_to_many :collections
  has_many :subject_sets, through: :set_member_subjects
  has_many :set_member_subjects

  validates_presence_of :project, :upload_user_id

  can_through_parent :project, :update, :index, :show, :destroy, :update_links,
                     :destroy_links, :versions, :version

  def migrated_subject?
    !!migrated
  end
end
