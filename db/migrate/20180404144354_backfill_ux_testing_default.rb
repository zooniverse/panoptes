class BackfillUxTestingDefault < ActiveRecord::Migration
  def change
    # moved to restartable rake task to avoid slowing
    # the db by surpassing the IOPS limits
    #
    # see lib/tasks/user.rake
    # task :backfill_ux_testing_email_field
  end
end
