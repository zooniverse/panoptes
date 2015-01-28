class RemoveOwnerFromProjects < ActiveRecord::Migration
  def change
    remove_reference :projects, :owner, polymorphic: true, index: true
  end
end
