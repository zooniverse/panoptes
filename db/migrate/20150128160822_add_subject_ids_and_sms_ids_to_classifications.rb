class AddSubjectIdsAndSmsIdsToClassifications < ActiveRecord::Migration
  def change
    remove_reference :classifications, :set_member_subject, index: true
    add_column :classifications, :set_member_subject_ids, :integer, array: true, default: []
  end
end
