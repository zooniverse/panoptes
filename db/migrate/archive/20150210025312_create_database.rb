class CreateDatabase < ActiveRecord::Migration
  def change
    # These are extensions that must be enabled in order to support this database
    enable_extension "plpgsql"

    create_table "access_control_lists", force: true do |t|
      t.integer  "user_group_id"
      t.string   "roles",         default: [], null: false, array: true
      t.integer  "resource_id"
      t.string   "resource_type"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "access_control_lists", ["resource_id", "resource_type"], name: "index_access_control_lists_on_resource_id_and_resource_type", using: :btree
    add_index "access_control_lists", ["user_group_id"], name: "index_access_control_lists_on_user_group_id", using: :btree

    create_table "authorizations", force: true do |t|
      t.integer  "user_id"
      t.string   "provider"
      t.string   "uid"
      t.string   "token"
      t.datetime "expires_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "authorizations", ["user_id"], name: "index_authorizations_on_user_id", using: :btree

    create_table "classifications", force: true do |t|
      t.integer  "project_id"
      t.integer  "user_id"
      t.integer  "workflow_id"
      t.json     "annotations"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "user_group_id"
      t.inet     "user_ip"
      t.boolean  "completed",         default: true, null: false
      t.boolean  "gold_standard"
      t.integer  "expert_classifier"
      t.json     "metadata",          default: {},   null: false
      t.integer  "subject_ids",       default: [],                array: true
    end

    add_index "classifications", ["project_id"], name: "index_classifications_on_project_id", using: :btree
    add_index "classifications", ["user_group_id"], name: "index_classifications_on_user_group_id", using: :btree
    add_index "classifications", ["user_id"], name: "index_classifications_on_user_id", using: :btree
    add_index "classifications", ["workflow_id"], name: "index_classifications_on_workflow_id", using: :btree

    create_table "collections", force: true do |t|
      t.string   "name"
      t.integer  "project_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "activated_state", default: 0, null: false
      t.string   "display_name"
      t.boolean  "private"
      t.integer  "lock_version",    default: 0
    end

    add_index "collections", ["project_id"], name: "index_collections_on_project_id", using: :btree

    create_table "collections_subjects", id: false, force: true do |t|
      t.integer "subject_id",    null: false
      t.integer "collection_id", null: false
    end

    create_table "memberships", force: true do |t|
      t.integer  "state",         default: 2,                null: false
      t.integer  "user_group_id"
      t.integer  "user_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "roles",         default: ["group_member"], null: false, array: true
      t.boolean  "identity",      default: false,            null: false
    end

    add_index "memberships", ["user_group_id"], name: "index_memberships_on_user_group_id", using: :btree
    add_index "memberships", ["user_id", "identity"], name: "index_memberships_on_user_id_and_identity", unique: true, where: "(identity = true)", using: :btree
    add_index "memberships", ["user_id"], name: "index_memberships_on_user_id", using: :btree

    create_table "oauth_access_grants", force: true do |t|
      t.integer  "resource_owner_id", null: false
      t.integer  "application_id",    null: false
      t.string   "token",             null: false
      t.integer  "expires_in",        null: false
      t.text     "redirect_uri",      null: false
      t.datetime "created_at",        null: false
      t.datetime "revoked_at"
      t.string   "scopes"
    end

    add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

    create_table "oauth_access_tokens", force: true do |t|
      t.integer  "resource_owner_id"
      t.integer  "application_id"
      t.string   "token",             null: false
      t.string   "refresh_token"
      t.integer  "expires_in"
      t.datetime "revoked_at"
      t.datetime "created_at",        null: false
      t.string   "scopes"
    end

    add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
    add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
    add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

    create_table "oauth_applications", force: true do |t|
      t.string   "name",                       null: false
      t.string   "uid",                        null: false
      t.string   "secret",                     null: false
      t.text     "redirect_uri",               null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "owner_id"
      t.string   "owner_type"
      t.integer  "trust_level",   default: 0,  null: false
      t.string   "default_scope", default: [],              array: true
    end

    add_index "oauth_applications", ["owner_id", "owner_type"], name: "index_oauth_applications_on_owner_id_and_owner_type", using: :btree
    add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

    create_table "project_contents", force: true do |t|
      t.integer  "project_id"
      t.string   "language"
      t.string   "title"
      t.text     "description"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "introduction"
      t.text     "science_case"
      t.json     "team_members"
      t.json     "guide"
    end

    add_index "project_contents", ["project_id"], name: "index_project_contents_on_project_id", using: :btree

    create_table "projects", force: true do |t|
      t.string   "name"
      t.string   "display_name"
      t.integer  "user_count"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "classifications_count", default: 0, null: false
      t.integer  "activated_state",       default: 0, null: false
      t.string   "primary_language"
      t.text     "avatar"
      t.text     "background_image"
      t.boolean  "private"
      t.integer  "lock_version",          default: 0
    end

    create_table "set_member_subjects", force: true do |t|
      t.integer  "state",          default: 0, null: false
      t.integer  "subject_set_id"
      t.integer  "subject_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.decimal  "priority"
      t.integer  "lock_version",   default: 0
    end

    add_index "set_member_subjects", ["subject_id"], name: "index_set_member_subjects_on_subject_id", using: :btree
    add_index "set_member_subjects", ["subject_set_id"], name: "index_set_member_subjects_on_subject_set_id", using: :btree

    create_table "subject_sets", force: true do |t|
      t.string   "display_name"
      t.integer  "project_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "set_member_subjects_count", default: 0, null: false
      t.json     "metadata"
      t.integer  "workflow_id"
      t.integer  "lock_version",              default: 0
      t.boolean  "expert_set"
    end

    add_index "subject_sets", ["project_id"], name: "index_subject_sets_on_project_id", using: :btree
    add_index "subject_sets", ["workflow_id"], name: "index_subject_sets_on_workflow_id", using: :btree

    create_table "subjects", force: true do |t|
      t.string   "zooniverse_id"
      t.json     "metadata"
      t.json     "locations"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "project_id"
      t.boolean  "migrated"
      t.integer  "lock_version",   default: 0
      t.string   "upload_user_id"
    end

    add_index "subjects", ["project_id"], name: "index_subjects_on_project_id", using: :btree
    add_index "subjects", ["zooniverse_id"], name: "index_subjects_on_zooniverse_id", unique: true, using: :btree

    create_table "user_collection_preferences", force: true do |t|
      t.json     "preferences"
      t.string   "roles",         default: [], null: false, array: true
      t.integer  "user_id"
      t.integer  "collection_id"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "user_collection_preferences", ["collection_id"], name: "index_user_collection_preferences_on_collection_id", using: :btree
    add_index "user_collection_preferences", ["user_id"], name: "index_user_collection_preferences_on_user_id", using: :btree

    create_table "user_groups", force: true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "classifications_count", default: 0,    null: false
      t.integer  "activated_state",       default: 0,    null: false
      t.string   "display_name"
      t.boolean  "private",               default: true, null: false
      t.integer  "lock_version",          default: 0
    end

    add_index "user_groups", ["name"], name: "index_user_groups_on_name", unique: true, using: :btree

    create_table "user_project_preferences", force: true do |t|
      t.integer  "user_id"
      t.integer  "project_id"
      t.boolean  "email_communication"
      t.json     "preferences"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "roles",               default: [], null: false, array: true
    end

    add_index "user_project_preferences", ["project_id"], name: "index_user_project_preferences_on_project_id", using: :btree
    add_index "user_project_preferences", ["user_id"], name: "index_user_project_preferences_on_user_id", using: :btree

    create_table "user_seen_subjects", force: true do |t|
      t.integer  "user_id"
      t.integer  "workflow_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "subject_ids", default: [], null: false, array: true
    end

    add_index "user_seen_subjects", ["user_id", "workflow_id"], name: "index_user_seen_subjects_on_user_id_and_workflow_id", using: :btree
    add_index "user_seen_subjects", ["workflow_id"], name: "index_user_seen_subjects_on_workflow_id", using: :btree

    create_table "user_subject_queues", force: true do |t|
      t.integer  "user_id"
      t.integer  "workflow_id"
      t.integer  "subject_ids",  default: [], null: false, array: true
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "lock_version", default: 0
    end

    add_index "user_subject_queues", ["user_id", "workflow_id"], name: "index_user_subject_queues_on_user_id_and_workflow_id", unique: true, using: :btree

    create_table "users", force: true do |t|
      t.string   "email",                       default: ""
      t.string   "encrypted_password",          default: "",       null: false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",               default: 0,        null: false
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "login",                                          null: false
      t.string   "hash_func",                   default: "bcrypt"
      t.string   "password_salt"
      t.string   "display_name"
      t.string   "zooniverse_id"
      t.string   "credited_name"
      t.integer  "classifications_count",       default: 0,        null: false
      t.integer  "activated_state",             default: 0,        null: false
      t.string   "languages",                   default: [],       null: false, array: true
      t.boolean  "global_email_communication"
      t.boolean  "project_email_communication"
      t.boolean  "admin",                       default: false,    null: false
      t.boolean  "banned",                      default: false,    null: false
    end

    add_index "users", ["display_name"], name: "index_users_on_display_name", unique: true, using: :btree
    add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
    add_index "users", ["login"], name: "index_users_on_login", unique: true, using: :btree
    add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

    create_table "versions", force: true do |t|
      t.string   "item_type",      null: false
      t.integer  "item_id",        null: false
      t.string   "event",          null: false
      t.string   "whodunnit"
      t.text     "object"
      t.datetime "created_at"
      t.text     "object_changes"
    end

    add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

    create_table "workflow_contents", force: true do |t|
      t.integer  "workflow_id"
      t.string   "language"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.json     "strings",     default: {}, null: false
    end

    add_index "workflow_contents", ["workflow_id"], name: "index_workflow_contents_on_workflow_id", using: :btree

    create_table "workflows", force: true do |t|
      t.string   "display_name"
      t.json     "tasks"
      t.integer  "project_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "classifications_count", default: 0,     null: false
      t.boolean  "pairwise",              default: false, null: false
      t.boolean  "grouped",               default: false, null: false
      t.boolean  "prioritized",           default: false, null: false
      t.string   "primary_language"
      t.string   "first_task"
      t.integer  "tutorial_subject_id"
      t.integer  "lock_version",          default: 0
    end

    add_index "workflows", ["project_id"], name: "index_workflows_on_project_id", using: :btree
    add_index "workflows", ["tutorial_subject_id"], name: "index_workflows_on_tutorial_subject_id", using: :btree

  end
end
