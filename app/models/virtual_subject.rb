# frozen_string_literal: true

class VirtualSubject
  VirtualMedium = Struct.new(:content_type, :url, keyword_init:true) do
    def url_for_format(_fmt = :get)
      url
    end
  end

  attr_reader :id, :metadata, :created_at, :updated_at, :zooniverse_id

  def initialize(id:, metadata:, locations: [], created_at: Time.now.utc, updated_at: Time.now.utc, zooniverse_id: nil)
    @id = id
    @metadata = metadata
    @locations = locations
    @created_at = created_at
    @updated_at = updated_at
    @zooniverse_id = zooniverse_id
  end

  def self.from_member_subjects(member_subjects, virtual_id: -1)
    key = member_subjects.map(&:id).join('-')
    vid = virtual_id

    # Build media list
    vmedia = member_subjects.flat_map do |subj|
      subj.ordered_locations.map do |loc|
        VirtualMedium.new(content_type: loc.content_type, url: loc.url_for_format(:get))
      end
    end

    new(
      id: vid,
      metadata: { '#subject_group_id' => true, '#group_subject_ids' => key },
      locations: vmedia
    )
  end

  def ordered_locations
    @locations
  end
end
