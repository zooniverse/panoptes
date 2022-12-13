class AddSubjectLimitToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subject_limit, :integer
  end
end
