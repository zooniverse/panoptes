class ForeignKeysClassifications < ActiveRecord::Migration
  class ClassificationSubject < ActiveRecord::Base
  end

  def change
    # Matches about 350 records
    classification_ids = Classification.joins("LEFT OUTER JOIN projects ON projects.id = classifications.project_id").where("classifications.project_id IS NOT NULL AND projects.id IS NULL").pluck("classifications.id")
    ClassificationSubject.where(classification_id: classification_ids).delete_all
    Recent.where(classification_id: classification_ids).delete_all
    Classification.where(id: classification_ids).delete_all

    # Matches about 70000 records, 55k from Wisconsin Wildlife Watch, 5.8k from Fossil Finders, but hardly any made while projects were live
    classification_ids = Classification.joins("LEFT OUTER JOIN workflows ON workflows.id = classifications.workflow_id").where("classifications.workflow_id IS NOT NULL AND workflows.id IS NULL").pluck("classifications.id")
    ClassificationSubject.where(classification_id: classification_ids).delete_all
    Recent.where(classification_id: classification_ids).delete_all
    Classification.where(id: classification_ids).delete_all

    add_foreign_key :classifications, :projects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :classifications, :users, on_update: :cascade, on_delete: :restrict
    add_foreign_key :classifications, :workflows, on_update: :cascade, on_delete: :restrict
    add_foreign_key :classifications, :user_groups, on_update: :cascade, on_delete: :restrict
  end
end
