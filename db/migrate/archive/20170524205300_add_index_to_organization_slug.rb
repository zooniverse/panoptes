class AddIndexToOrganizationSlug < ActiveRecord::Migration
  def change
    # Ensure that all slugs are populated by acts_as_url callback
    Organization.all.each(&:save)
    add_index :organizations, :slug, unique: true
  end
end
