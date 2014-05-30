class Project < ActiveRecord::Base
  include Ownable

  has_many :workflows
  has_many :subject_sets

<<<<<<< HEAD
=======
  validates_presence_of :owner

  def to_param
    "#{owner.name}/#{self.name}"
  end
>>>>>>> origin/feature-named_urls
end
