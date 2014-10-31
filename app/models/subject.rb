class Subject < ActiveRecord::Base
  extend ControlControl::Resource
  include RoleControl::Ownable
  include RoleControl::Adminable
  include Linkable

  has_paper_trail only: [:metadata, :locations]

  belongs_to :project
  has_and_belongs_to_many :collections
  has_many :subject_sets, through: :set_member_subjects
  has_many :set_member_subjects
  
  attr_accessible :project_id, :metadata, :locations, :owner
  validates_presence_of :project

  def self.scope_for(action, actor)
    if action == :show
      all
    else
      actor.owner.subjects
    end
  end

  def self.can_create?(actor)
    true
  end

  def locations=(locations)
    locations = locations.reduce({}) do |locs, (location, mime)|
      locs[location] = {mime_type: mime,
                        s3_path: subject_path(location, mime)}
      locs
    end
    
    write_attribute(:locations, locations)
  end

  def subject_path(location, mime)
    extension = MIME::Types[mime].first.extensions.first
    "#{project.id}/#{location}/#{id}.#{extension}"
  end
end
