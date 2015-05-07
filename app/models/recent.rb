class Recent < ActiveRecord::Base
  belongs_to :classification
  belongs_to :subject

  has_many :locations, through: :subject

  has_one :project, through: :classification
  has_one :workflow, through: :classification
  has_one :user, through: :classification
  has_one :user_group, through: :classification
end

