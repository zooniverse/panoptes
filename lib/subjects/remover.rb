module Subjects
  class Remover
    attr_reader :subject_id, :panoptes_client, :subject_set_id

    def initialize(subject_id, client=nil, subject_set_id=nil)
      @subject_id = subject_id
      @panoptes_client = client || Panoptes::Client.new(env: Rails.env)
      @subject_set_id = subject_set_id
    end

    def cleanup(hard_delete: false)
      if hard_delete
        @orphan_subject = Subject.find_by(id: subject_id)
        return destroy_subject_media unless @orphan_subject
      end

      if hard_delete || can_be_removed?
        locations = orphan_subject.locations
        set_member_subjects = orphan_subject.set_member_subjects
        workflow_ids = orphan_subject.workflows.pluck(:id)
        subject_set_ids = set_member_subjects.pluck(:subject_set_id) if hard_delete
        if hard_delete
          workflow_ids |= orphan_subject_sws_scope.pluck(:workflow_id)
        end
        ActiveRecord::Base.transaction do
          orphan_subject.lock! if hard_delete
          remove_used_subject_links if hard_delete
          # clean up the linked sws records, https://github.com/zooniverse/Panoptes/pull/2822
          orphan_subject_sws_scope.delete_all
          orphan_subject.delete
          locations.map(&:destroy) unless hard_delete
          set_member_subjects.map(&:destroy)
        end
        notify_subject_selector(workflow_ids)
        if hard_delete
          subject_set_ids.each { |id| SubjectSetSubjectCounterWorker.perform_async(id) }
          workflow_ids.each do |id|
            WorkflowSubjectsCountWorker.perform_async(id)
            WorkflowRetiredCountWorker.perform_async(id)
          end
          destroy_subject_media
        end
        true
      else
        false
      end
    end

    private

    def remove_used_subject_links
      delete_subject_rows(:classification_subjects)
      delete_subject_rows(:recents_old) if Subject.connection.data_source_exists?(:recents_old)
      Recent.where(subject_id: subject_id).delete_all
      Collection.where(default_subject_id: subject_id).update_all(default_subject_id: nil, updated_at: Time.current)
      orphan_subject.collections_subjects.find_each(&:destroy!)
      Workflow.where(tutorial_subject_id: subject_id).update_all(tutorial_subject_id: nil, updated_at: Time.current)

      connection = Subject.connection
      connection.execute <<-SQL
        UPDATE gold_standard_annotations
        SET subject_id = NULL, updated_at = CURRENT_TIMESTAMP
        WHERE subject_id = #{connection.quote(subject_id)}
      SQL
    end

    def delete_subject_rows(table_name)
      connection = Subject.connection
      connection.execute <<-SQL
        DELETE FROM #{connection.quote_table_name(table_name)}
        WHERE subject_id = #{connection.quote(subject_id)}
      SQL
    end

    def destroy_subject_media
      # Run existing Medium callbacks only after subject deletion commits.
      # The polymorphic link also lets retries find media after the subject is gone.
      Medium.where(linked_type: 'Subject', linked_id: subject_id).find_each(&:destroy!)
      true
    end

    def can_be_removed?
      return false if has_been_collected_or_classified?

      return false if belongs_to_other_subject_set?

      return false if has_been_talked_about?

      return false if has_been_counted_or_retired?

      # subject has no record of use in zooniverse
      true
    end

    def orphan_subject_scope
      Subject
      .where(id: subject_id)
      .joins("LEFT OUTER JOIN classification_subjects ON classification_subjects.subject_id = subjects.id")
      .where("classification_subjects.subject_id IS NULL")
      .joins("LEFT OUTER JOIN collections_subjects ON collections_subjects.subject_id = subjects.id")
      .where("collections_subjects.subject_id IS NULL")
    end

    def orphan_subject
      @orphan_subject ||= orphan_subject_scope.first
    end

    def has_been_collected_or_classified?
      !orphan_subject
    end

    def belongs_to_other_subject_set?
      return false if subject_set_id.nil?

      orphan_subject.set_member_subjects.where.not(subject_set_id: subject_set_id).count.positive?
    end

    def has_been_talked_about?
      panoptes_client.discussions(
        focus_id: subject_id,
        focus_type: 'Subject'
      ).any?
    end

    def notify_subject_selector(workflow_ids)
      workflow_ids.each do |workflow_id|
        NotifySubjectSelectorOfRetirementWorker.perform_async(orphan_subject.id, workflow_id)
      end
    end

    def orphan_subject_sws_scope
      SubjectWorkflowStatus.where(subject_id: subject_id)
    end

    def has_been_counted_or_retired?
      orphan_subject_sws_scope
      .where("classifications_count > 0 OR retired_at IS NOT NULL")
      .exists?
    end
  end
end
