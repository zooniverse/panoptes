# frozen_string_literal: true

module SubjectGroups
  class Create < Operation
    string  :project_id
    string  :uploader_id
    array   :subject_ids
    integer :subject_ids_size, default: -> { subject_ids.size }
    integer :group_size

    validates :subject_ids_size, numericality: { greater_than_or_equal_to: ENV.fetch('SUBJECT_GROUP_MIN_SIZE', 2).to_i }
    validate :group_size, :ensure_subject_ids_size_matches_group_size

    def execute
      group_subjects_in_order = find_subjects_in_order(subject_ids)

      # ensure we find all the subjects we're looking for
      ensure_all_subjects_exist(group_subjects_in_order.size)

      subject_group = build_subject_group(group_subjects_in_order)

      # ensure this save is 'isolated' from any surrounding transaction
      # https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
      SubjectGroup.transaction(requires_new: true) do
        # save this subject_group and all the associated records (members, group_subject)
        subject_group.save!
        # track the subject_group on the placeholder subject metadata
        # useful for the subject exports and downstream analysis
        # to know how the group is comprised of what subjects
        # possible use in online retirement as well - TBD
        update_group_subject_metadata(subject_group)
      end
      subject_group
    end

    private

    def ensure_all_subjects_exist(group_subjects_in_order_size)
      return if subject_ids_size == group_subjects_in_order_size

      raise Error, 'Number of found subjects does not match the number of subject_ids'
    end

    def ensure_subject_ids_size_matches_group_size
      return if subject_ids_size == group_size

      raise Error, 'Number of subject_ids does not match the group_size'
    end

    def build_subject_group(subjects)
      subject_group = SubjectGroup.new(project: project, key: subject_group_key)
      subjects.each_with_index do |subject, index|
        subject_group.subject_group_members << build_subject_group_member(subject_group, subject, index)
      end
      subject_group.group_subject = build_group_subject
      subject_group
    end

    def subject_group_key
      subject_ids.join('-')
    end

    def project
      @project ||= Project.find(project_id)
    end

    def uploader
      @uploader ||= User.find(uploader_id)
    end

    def find_subjects_in_order(subject_ids)
      @find_subjects_in_order ||=
        Subject
        .active
        .where(id: subject_ids)
        .order(
          "idx(array[#{subject_ids.join(',')}], id)"
        )
        .load
    end

    def build_subject_group_member(subject_group, subject, index)
      SubjectGroupMember.new(
        project: project,
        subject: subject,
        subject_group: subject_group,
        display_order: index
      )
    end

    def build_group_subject
      Subject.new(project: project, uploader: uploader) do |subject|
        subject.locations.build(subject_location_params)
      end
    end

    def subject_location_params
      subject_locations = find_subjects_in_order(subject_ids).map(&:locations).flatten
      external_locations_subject_id_lut = {}
      external_locations = subject_locations.map do |loc|
        extension = File.extname(loc.src).downcase[1..-1]
        mime_type = Mime::Type.lookup_by_extension(extension).to_s
        media_url = "https://#{loc.src}"
        # track the subject URL and the originating subject id
        external_locations_subject_id_lut[media_url] = loc.linked_id
        # return the mime / url combination for building the media location resources
        { mime_type => media_url }
      end
      # build the subject location params for use in the AR association builder
      build_external_location_params(external_locations, external_locations_subject_id_lut)
    end

    def build_external_location_params(media_locations, media_locations_subject_id_lut)
      Subject.location_attributes_from_params(media_locations).map do |location_param|
        media_url = location_param[:src]
        media_subject_id = media_locations_subject_id_lut[media_url]
        # store the originating subject resource id to ensure track
        # how the group_subject media location resources are built and to
        # specifically understand the intended subject -> media location ordering
        # without this we may be incorrectly showing a different subject ids' media image
        # and thus breaking the downstream classification data
        location_param[:metadata][:originating_subject_id] = media_subject_id
        location_param
      end

    end

    def update_group_subject_metadata(subject_group)
      group_subject = subject_group.group_subject
      group_subject_metadata = group_subject.metadata
      # ensure these metadata fields are hidden
      group_subject_metadata['#subject_group_id'] = subject_group.id
      group_subject_metadata['#group_subject_ids'] = subject_group.key
      group_subject.update_column(:metadata, group_subject_metadata) #rubocop:disable Rails/SkipsModelValidations
    end
  end
end
