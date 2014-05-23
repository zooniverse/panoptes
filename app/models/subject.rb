class Subject < ActiveRecord::Base
  has_and_belongs_to_many :user_subject_collections
end
