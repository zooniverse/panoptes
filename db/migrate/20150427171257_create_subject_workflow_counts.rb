class CreateSubjectWorkflowCounts < ActiveRecord::Migration
  def change
    create_table :subject_workflow_counts do |t|
      t.references :set_member_subject, index: true, foreign_key: true
      t.references :workflow, index: true, foreign_key: true
      t.integer :classifications_count, default: 0

      t.timestamps null: false
    end

    SetMemberSubject.find_each do |sms|
      (sms.subject_set.try(:workflows) || []).each do |w|
        SubjectWorkflowCount.create!(set_member_subject: sms, workflow: w, classifications_count: sms.classification_count)
      end
    end

    remove_column :set_member_subjects, :classification_count
  end
end
