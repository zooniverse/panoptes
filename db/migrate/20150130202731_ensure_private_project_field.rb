class EnsurePrivateProjectField < ActiveRecord::Migration

  class Project < ActiveRecord::Base
  end

  def up
    Project.where(private: nil).update_all(private: true)
  end

  def down
  end
end
