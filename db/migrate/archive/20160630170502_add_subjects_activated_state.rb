class AddSubjectsActivatedState < ActiveRecord::Migration
  def change
    add_column :subjects, :activated_state, :integer
  end
end
