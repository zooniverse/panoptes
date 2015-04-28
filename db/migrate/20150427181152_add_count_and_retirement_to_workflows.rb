class AddCountAndRetirementToWorkflows < ActiveRecord::Migration
  def change
    add_column :workflows, :retirement, :jsonb, default: {}

    SubjectSet.find_each do |ss|
      (ss.try(:workflows) || []).each do |w|
        w.update_attribute(:retirement, ss.retirement)
      end
    end

    remove_column :subject_sets, :retirement
  end
end
