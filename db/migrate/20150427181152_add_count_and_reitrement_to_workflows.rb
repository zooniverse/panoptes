class AddCountAndReitrementToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :retirement, :jsonb, default: {}

    SubjectSet.find_each do |ss|
      ss.workflows.each do |w|
        w.update!(retirement: ss.retirement)
      end
    end

    remove_column :subject_sets, :retirement
  end
end
