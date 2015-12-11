class CreateSubjectSetsWorkflows < ActiveRecord::Migration
  def up
    create_table :subject_sets_workflows do |t|
      t.references :workflow, index: true, foreign_key: true
      t.references :subject_set, index: true, foreign_key: true
    end

    add_column :workflows, :retired_set_member_subjects_count, :integer, default: 0

    SubjectSet.where.not(workflow_id: nil).find_each do |ss|
      if w = Workflow.find_by(id: ss.workflow_id)
        ActiveRecord::Base.connection.execute("INSERT INTO \"subject_sets_workflows\" (workflow_id, subject_set_id) VALUES (#{ss.workflow_id},#{ss.id})")
        w.update_attribute(:retired_set_member_subjects_count, ss.retired_set_member_subjects_count)
      end
    end

    remove_column :subject_sets, :workflow_id
    remove_column :subject_sets, :retired_set_member_subjects_count
  end

  def down
    add_column :subject_sets, :workflow_id, :integer, index: true, foreign_key: true
    drop_table :subject_sets_workflows
  end
end
