# frozen_string_literal: true

module SubjectGroups
  class Selection < Operation
    integer :num_rows
    integer :num_columns
    string :uploader_id
    # allow all attributes of params through
    hash :params, strip: false

    object :user, class: ApiUser

    def execute
      subject_selector = Subjects::Selector.new(user.user, selector_params)
      validate_workflow_group_dimensions(subject_selector.workflow, num_rows, num_columns)

      selected_subject_ids = subject_selector.get_subject_ids
      subject_group_key = selected_subject_ids.join('-')

      # re-use any existing SubjectGroup based on key lookup
      subject_group = SubjectGroup.find_by(key: subject_group_key)

      # if we didn't find it, create a new subject group from the selected ids
      subject_group ||= SubjectGroups::Create.run!(
        subject_ids: selected_subject_ids,
        uploader_id: uploader_id,
        project_id: subject_selector.workflow.project_id.to_s
      )
      OpenStruct.new(subject_selector: subject_selector, subject_group: subject_group)
    end

    private

    # update the page_size for the requested number of group subjects
    def selector_params
      params[:page_size] = num_rows * num_columns
      params
    end

    def validate_workflow_group_dimensions(workflow, num_rows, num_columns)
      if (subject_group_config = workflow.configuration['subject_group'])
        num_rows_match = subject_group_config['num_rows'] == num_rows
        num_columns_match = subject_group_config['num_columns'] == num_columns
        return if num_rows_match && num_columns_match
      end

      raise Error, 'Supplied num_rows and num_colums mismatches the workflow configuration'
    end

  end
end
