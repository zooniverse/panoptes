# frozen_string_literal: true

class SubjectGroup < ActiveRecord::Base
  belongs_to :project

  has_many :members, class_name: 'SubjectGroupMember', dependent: :destroy
  has_many :subjects, through: :members
  # a 'group' subject to record the grouped view of linked subject locations
  # for use in talk and to collect retirement information about the group
  belongs_to :group_subject, class_name: 'Subject'

  validates :project, presence: true
  validates :members, presence: true

  # ensure the key is set before save - manually too
  before_save :set_key, on: :create
  before_save :create_group_subject, on: :create

  # custom member record association ordering
  # to ensure we specify the key order and uniquely identify this subject group
  def members_in_display_order
    members.sort { |m| m.display_order } # rubocop:disable Style/SymbolProc
  end

  private

  def set_key
    return if members.empty?

    self.key = members_in_display_order.map(&:subject_id).join('-')
  end

  # TODO: refactor this to it's own collaborator to create the group_subject
  # call this from the controller / service object
  #
  # UPDATE this subject_group model to not do any attribute settings on callbacks
  # simplify the model lifecycle and instead
  # ensure the group_subject and key are present validations
  def create_group_subject
    locations_in_order = members_in_display_order.map(&:subject).map(&:locations).flatten

    locations = []
    locations_in_order.each do |loc|
      extension = File.extname(loc.src).downcase[1..-1]
      mime_type = Mime::Type.lookup_by_extension(extension).to_s
      locations << { mime_type => "https://#{loc.src}" }
    end

# which project will this subject be associated with,
# for now hard code these via env vars
# if the controller doesn't match - raise!!

    project = Project.find(ENV.fetch('SUBJECT_GROUP_PROJECT_ID'))
    uploader = User.find(ENV.fetch('SUBJECT_GROUP_UPLOAD_USER_ID'))

    subject = Subject.new(project: project, uploader: uploader) do |subject|
      location_params = Subject.location_attributes_from_params(locations)
      subject.locations.build(location_params)
    end
    subject.save!
    self.group_subject = subject
  end
end
