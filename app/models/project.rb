class Project < ActiveRecord::Base
  include Ownable

  has_many :workflows
  has_many :subject_sets

  def to_param
    "#{owner.name}/#{self.name}"
  end
end
