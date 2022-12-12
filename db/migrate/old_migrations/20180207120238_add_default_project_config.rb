class AddDefaultProjectConfig < ActiveRecord::Migration
  def column_name
    :configuration
  end

  def update_configuration_column(default, null)
    change_column(:projects, column_name, :jsonb, default: default, null: null)
  end

  def up
    Project.where(column_name => nil).update_all(column_name => {})
    update_configuration_column({}, false)
  end

  def down
    update_configuration_column(nil, true)
  end
end
