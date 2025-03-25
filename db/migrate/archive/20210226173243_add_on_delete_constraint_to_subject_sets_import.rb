# frozen_string_literal: true

class AddOnDeleteConstraintToSubjectSetsImport < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        remove_foreign_key :subject_set_imports, :subject_sets
        add_foreign_key :subject_set_imports, :subject_sets, on_update: :cascade, on_delete: :cascade, validate: false
      end

      dir.down do
        remove_foreign_key :subject_set_imports, :subject_sets
        add_foreign_key :subject_set_imports, :subject_sets
      end
    end
  end
end
