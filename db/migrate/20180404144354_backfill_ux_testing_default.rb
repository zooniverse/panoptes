class BackfillUxTestingDefault < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    User.find_in_batches do |users|
      null_ux_testing_user_scope = User.where(
        id: users.map(&:id),
        ux_testing_email_communication: nil
      )
      null_ux_testing_user_scope.update_all(
        ux_testing_email_communication: false
      )
    end
  end
end
