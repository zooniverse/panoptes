# frozen_string_literal: true

module Subjects
  class SelectionByIds < Operation
    integer :workflow_id
    string :ids
    # ensure ids param conforms to the non zero digit comma delimited format, e.g. 1,2,3 (max of 10)
    validates :ids, format: {
      with: /\A(\d+)(?:,\d+){0,9}\z/,
      message: 'must be a comma seperated list of digits (max 10)'
    }
    # lazily loaded and split the formated ids string up
    array :subject_ids, default: -> { ids.split(',') }

    def execute
      validate_workflow_subject_linkage

      Subject.active.where(id: subject_ids).order("idx(array[#{subject_ids.join(',')}], id)")
    end

    private

    def validate_workflow_subject_linkage
      # query how many times a subject links to subject_sets for the workflow
      subject_workflow_links_count = SetMemberSubject.by_subject_workflow(subject_ids, workflow_id).group(:subject_id).count
      # now count the unique number of subject_ids groups keys
      # as these keys represent the linkage between a workflow and a subject
      workflow_subject_link_counts = subject_workflow_links_count.keys.count
      return if workflow_subject_link_counts == subject_ids.size

      raise Error, 'Supplied subject ids do not belong to the workflow'
    end
  end
end
