# frozen_string_literal: true

class AddManifestCountToSubjectSetImport < ActiveRecord::Migration
  def change
    add_column :subject_set_imports, :manifest_count, :integer, default: 0
  end
end
