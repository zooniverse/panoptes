class RemoveOwnerFromSubjects < ActiveRecord::Migration
  def change
    remove_reference :subjects, :owner, polymorphic: true, index: true
  end
end
