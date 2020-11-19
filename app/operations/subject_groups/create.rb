# frozen_string_literal: true

module SubjectGroups
  class Create < Operation
    string :project_id
    string :uploader_id
    array :subject_ids

    def execute
      group_subjects_in_order = find_subjects_in_order(subject_ids)
      ensure_all_subjects_exist(subject_ids.size, group_subjects_in_order.size)

      subject_group = build_subject_group(group_subjects_in_order)

      # ensure this save is 'isolated' from any surrounding transaction
      # https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#module-ActiveRecord::Transactions::ClassMethods-label-Nested+transactions
      SubjectGroup.transaction(requires_new: true) do
        # save this subject_group and all the associated records (members, group_subject)
        subject_group.save!
      end
      subject_group
    end

    private

    def build_subject_group(subjects)
      subject_group = SubjectGroup.new(project: project, key: subject_group_key)
      subjects.each_with_index do |subject, index|
        subject_group.members << build_subject_group_member(subject_group, subject, index)
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
        # TODO: look at adding some of the selection context in here
        # is the workflow finished? (useful probs not)
        # selecter state? is probably useful
        # context: {hash_of_useful_selector_context_info}
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
      external_locations = subject_locations.map do |loc|
        extension = File.extname(loc.src).downcase[1..-1]
        mime_type = Mime::Type.lookup_by_extension(extension).to_s
        { mime_type => "https://#{loc.src}" }
      end
      Subject.location_attributes_from_params(external_locations.reverse)
    end

    def ensure_all_subjects_exist(subject_ids_size, group_subjects_in_order_size)
      return if subject_ids_size == group_subjects_in_order_size

      raise Error, 'Number of found subjects does not match the size of param subject_ids'
    end
  end
end
