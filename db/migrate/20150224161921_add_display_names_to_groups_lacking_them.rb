class AddDisplayNamesToGroupsLackingThem < ActiveRecord::Migration
  def change
    UserGroup.where(display_name: nil).each do |group|
      group.display_name = group.name
      group.save!
    end
  end
end
