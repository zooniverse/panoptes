class ForeignKeys < ActiveRecord::Migration
  class ClassificationSubject < ActiveRecord::Base
  end

  def change
    add_foreign_key :access_control_lists, :user_groups, on_update: :cascade, on_delete: :cascade

    Aggregation.joins("LEFT OUTER JOIN workflows ON workflows.id = aggregations.workflow_id").where("workflows.id IS NULL").delete_all
    add_foreign_key :aggregations, :workflows, on_update: :cascade, on_delete: :cascade
    add_foreign_key :aggregations, :subjects, on_update: :cascade, on_delete: :cascade

    add_foreign_key :authorizations, :users, on_update: :cascade, on_delete: :cascade

    # Classification foreign keys are done all the way at the end because we might be deleting projects or workflows
    # that they refer to on the following lines. Apart from that, everything is in alphabetical order, same as the structure.sql

    # Commented out add_foreign_key calls are ones that already exist. Left them in here so that it's
    # easier to check if I caught all of them.
    #
    # add_foreign_key :classification_subjects, :classifications
    # add_foreign_key :classification_subjects, :subjects

    add_foreign_key :collections_subjects, :subjects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :collections_subjects, :collections, on_update: :cascade, on_delete: :cascade

    add_foreign_key :field_guides, :projects, on_update: :cascade, on_delete: :cascade

    add_foreign_key :memberships, :user_groups, on_update: :cascade, on_delete: :cascade
    add_foreign_key :memberships, :users, on_update: :cascade, on_delete: :cascade

    add_foreign_key :oauth_access_grants, :users, column: :resource_owner_id, on_update: :cascade, on_delete: :cascade
    add_foreign_key :oauth_access_grants, :oauth_applications, column: :application_id, on_update: :cascade, on_delete: :cascade

    add_foreign_key :oauth_access_tokens, :users, column: :resource_owner_id, on_update: :cascade, on_delete: :cascade
    add_foreign_key :oauth_access_tokens, :oauth_applications, column: :application_id, on_update: :cascade, on_delete: :cascade

    ProjectContent.joins("LEFT OUTER JOIN projects ON projects.id = project_contents.project_id").where("projects.id IS NULL").delete_all
    add_foreign_key :project_contents, :projects, on_update: :cascade, on_delete: :cascade

    ProjectPage.joins("LEFT OUTER JOIN projects ON projects.id = project_pages.project_id").where("projects.id IS NULL").delete_all
    add_foreign_key :project_pages, :projects, on_update: :cascade, on_delete: :cascade

    # add_foreign_key :recents, :classifications
    # add_foreign_key :recents, :subjects

    SetMemberSubject.joins("LEFT OUTER JOIN subject_sets ON subject_sets.id = set_member_subjects.subject_set_id").where("subject_sets.id IS NULL").delete_all
    SetMemberSubject.joins("LEFT OUTER JOIN subjects ON subjects.id = set_member_subjects.subject_id").where("subjects.id IS NULL").delete_all
    add_foreign_key :set_member_subjects, :subject_sets, on_update: :cascade, on_delete: :cascade
    add_foreign_key :set_member_subjects, :subjects, on_update: :cascade, on_delete: :cascade

    SubjectQueue.joins("LEFT OUTER JOIN subject_sets ON subject_sets.id = subject_queues.subject_set_id").where("subject_sets.id IS NULL").delete_all
    add_foreign_key :subject_queues, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :subject_queues, :workflows, on_update: :cascade, on_delete: :cascade
    add_foreign_key :subject_queues, :subject_sets, on_update: :cascade, on_delete: :restrict

    add_foreign_key :subject_sets, :projects, on_update: :cascade, on_delete: :cascade

    # add_foreign_key :subject_sets_workflows, :subject_sets
    # add_foreign_key :subject_sets_workflows, :workflows

    # add_foreign_key :subject_workflow_counts, :workflows
    # add_foreign_key :subject_workflow_counts, :subjects

    Subject.joins("LEFT OUTER JOIN projects ON projects.id = subjects.project_id").where("projects.id IS NULL").update_all(project_id: nil)
    add_foreign_key :subjects, :projects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :subjects, :users, column: :upload_user_id, on_update: :cascade, on_delete: :restrict

    # add_foreign_key :tagged_resources, :tags

    # add_foreign_key :tutorials, :projects

    add_foreign_key :user_collection_preferences, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_collection_preferences, :collections, on_update: :cascade, on_delete: :cascade

    UserProjectPreference.joins("LEFT OUTER JOIN projects ON projects.id = user_project_preferences.project_id").where("projects.id IS NULL").delete_all
    add_foreign_key :user_project_preferences, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_project_preferences, :projects, on_update: :cascade, on_delete: :cascade

    UserSeenSubject.joins("LEFT OUTER JOIN workflows ON workflows.id = user_seen_subjects.workflow_id").where("workflows.id IS NULL").delete_all
    add_foreign_key :user_seen_subjects, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :user_seen_subjects, :workflows, on_update: :cascade, on_delete: :cascade

    add_foreign_key :users, :projects, on_update: :cascade, on_delete: :restrict

    WorkflowContent.joins("LEFT OUTER JOIN workflows ON workflows.id = workflow_contents.workflow_id").where("workflows.id IS NULL").delete_all
    add_foreign_key :workflow_contents, :workflows, on_update: :cascade, on_delete: :cascade

    # add_foreign_key :workflow_tutorials, :workflows
    # add_foreign_key :workflow_tutorials, :tutorials

    Workflow.joins("LEFT OUTER JOIN projects ON projects.id = workflows.project_id").where("projects.id IS NULL").delete_all
    add_foreign_key :workflows, :projects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :workflows, :subjects, column: :tutorial_subject_id, on_update: :cascade, on_delete: :restrict

    # Matches about 350 records
    classification_ids = Classification.joins("LEFT OUTER JOIN projects ON projects.id = classifications.project_id").where("projects.id IS NULL").pluck("classifications.id")
    ClassificationSubject.where(classification_id: classification_ids).delete_all
    Recent.where(classification_id: classification_ids).delete_all
    Classification.where(id: classification_ids).delete_all

    # Matches about 70000 records, 55k from Wisconsin Wildlife Watch, 5.8k from Fossil Finders, but hardly any made while projects were live
    classification_ids = Classification.joins("LEFT OUTER JOIN workflows ON workflows.id = classifications.workflow_id").where("workflows.id IS NULL").pluck("classifications.id")
    ClassificationSubject.where(classification_id: classification_ids).delete_all
    Recent.where(classification_id: classification_ids).delete_all
    Classification.where(id: classification_ids).delete_all

    add_foreign_key :classifications, :projects, on_update: :cascade, on_delete: :restrict
    add_foreign_key :classifications, :users, on_update: :cascade, on_delete: :restrict
    add_foreign_key :classifications, :workflows, on_update: :cascade, on_delete: :restrict
    add_foreign_key :classifications, :user_groups, on_update: :cascade, on_delete: :restrict
  end
end
