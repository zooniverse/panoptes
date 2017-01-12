class Recent < ActiveRecord::Base
  belongs_to :classification
  belongs_to :subject

  has_many :locations, through: :subject

  has_one :project, through: :classification
  has_one :workflow, through: :classification
  has_one :user, through: :classification
  has_one :user_group, through: :classification

  belongs_to :project
  belongs_to :workflow
  belongs_to :user
  belongs_to :user_group

  validates_presence_of :classification, :subject

  # TODO: modify the following validation to run all the time
  # once the recents schema has been migrated from has_one through associations
  validates_presence_of :project_id, :workflow_id, :user_id, only: :create

  before_validation :copy_classification_fkeys

  def self.create_from_classification(classification)
    classification.subject_ids.map do |sid|
      create!({ subject_id: sid, classification: classification })
    end
  end

  private

  def copy_classification_fkeys
    if classification
      %W(project_id workflow_id user_id user_group_id).each do |key|
        self.send("#{key}=", classification.send(key))
      end
    end
  end
end
