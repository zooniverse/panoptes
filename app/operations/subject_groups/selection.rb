# frozen_string_literal: true

module SubjectGroups
  class Selection < Operation
    integer :num_rows
    integer :num_columns
    integer :grid_size, default: -> { num_rows.to_i * num_columns.to_i }
    string :uploader_id
    # allow all attributes of params through
    hash :params, strip: false
    object :user, class: ApiUser
    # ensure the num_rows & columns are integers between 1 and 10
    validates :num_rows, numericality: { less_than: 10, greater_than_or_equal_to: 1 }
    validates :num_columns, numericality: { less_than: 10, greater_than_or_equal_to: 1 }
    validates :grid_size, numericality: { less_than_or_equal_to: ENV.fetch('SUBJECT_GROUP_MAX_GRID_SIZE', 25) }

    def execute
      subject_selector = Subjects::Selector.new(user.user, selector_params)
      validate_workflow_group_dimensions(
        subject_selector.workflow.configuration['subject_group'],
        num_rows,
        num_columns
      )

      subject_groups = find_or_create_subject_groups(
        subject_selector.get_subject_ids,
        subject_selector.workflow.project_id.to_s
      )

      OpenStruct.new(subject_selector: subject_selector, subject_groups: subject_groups)
    end

    private

    # update the params to include the page_size value
    # to equal the requested number of group subjects * the number of groups to select at once
    #
    #  Note: PFE / FEM requires at min 3 subjects being in the JS queue at any given time.
    #  If the JS queue drops below 3 the client will request more data from this end point.
    #  Thus we attempt to optimize the number of selection / subject group create requests
    def selector_params
      params[:page_size] = grid_size * ENV.fetch('SUBJECT_GROUPS_NUM_TO_SELECT', 3)
      params
    end

    def validate_workflow_group_dimensions(subject_group_config, num_rows, num_columns)
      if subject_group_config
        num_rows_match = subject_group_config['num_rows'] == num_rows
        num_columns_match = subject_group_config['num_columns'] == num_columns
        return if num_rows_match && num_columns_match
      end

      raise Error, 'Supplied num_rows and num_colums mismatches the workflow configuration'
    end

    def find_or_create_subject_groups(selected_subject_ids, project_id)
      [].tap do |subject_groups|
        SubjectGroup.transaction do
          # split the subject ids into equal groups of `grid_size`
          selected_subject_ids.each_slice(grid_size) do |group_subject_ids|
            subject_group_key = group_subject_ids.join('-')

            # re-use any existing SubjectGroup based on key lookup
            subject_group = SubjectGroup.find_by(key: subject_group_key)

            # if we didn't find it, create a new subject group from the selected ids
            subject_group ||= SubjectGroups::Create.run!(
              subject_ids: selected_subject_ids,
              uploader_id: uploader_id,
              project_id: project_id
            )
            subject_groups << subject_group
          end
        end
      end
    end
  end
end
