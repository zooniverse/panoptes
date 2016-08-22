class SubjectActivatedStateDefault < ActiveRecord::Migration
  def change
    change_column_default(:subjects, :activated_state, false)
  end
end
