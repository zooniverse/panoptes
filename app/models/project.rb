class Project < ActiveRecord::Base
  include Ownable
  include SubjectCounts

  has_many :workflows
  has_many :subject_sets
  has_many :classifications

  def to_param
    "#{owner.name}/#{self.name}"
  end

end
