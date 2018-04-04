class BackfillUxTestingDefault < ActiveRecord::Migration
  disable_ddl_transaction!

  def backfill_user_ux_testing(user_ids)
    User.where(id: user_ids).update_all(ux_testing_email_communication: false)
  end

  def change
    User.find_in_batches do |users|
      backfill_user_ux_testing(users.map(&:id))
    end
  end
end
