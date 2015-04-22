class CreateSubjectSetsWorkflows < ActiveRecord::Migration
  def up
    create_table :subject_sets_workflows do |t|
      t.references :workflow, index: true, foreign_key: true
      t.references :subject_set, index: true, foreign_key: true
    end

    SubjectSet.all.find_each do |ss|
      ActiveRecord::Base.connection.execute("INSERT (#{ss.worfklow_id},#{ss.id}) INTO 'subject_sets_workflows' ('workflow_id', 'subject_set_id')")
    end

    remove_column :subject_sets, :workflow_id
  end

  def down
    add_column :subject_sets, :workflow_id, :integer, index: true, foreign_key: true
    drop_table :subject_sets_workflows
  end
end
