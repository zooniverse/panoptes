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

  def self.create_from_classification(classification)
    classification.subject_ids.each do |sid|
      create!(subject_id: sid, classification: classification)
    end
  end
end
