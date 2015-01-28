class RemoveOwnerFromCollections < ActiveRecord::Migration
  def change
    remove_reference :collections, :owner, polymorphic: true, index: true
  end
end
