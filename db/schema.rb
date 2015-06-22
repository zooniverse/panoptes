# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150622085848) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "intarray"
  enable_extension "pg_trgm"

  create_table "access_control_lists", force: :cascade do |t|
    t.integer  "user_group_id", index: {name: "index_access_control_lists_on_user_group_id"}
    t.string   "roles",         default: [], null: false, array: true, index: {name: "index_access_control_lists_on_roles", using: :gin}
    t.integer  "resource_id",   index: {name: "index_access_control_lists_on_resource_id_and_resource_type", with: ["resource_type"]}
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "aggregations", force: :cascade do |t|
    t.integer  "workflow_id", index: {name: "index_aggregations_on_workflow_id"}
    t.integer  "subject_id",  index: {name: "index_aggregations_on_subject_id"}
    t.jsonb    "aggregation", default: {}, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authorizations", force: :cascade do |t|
    t.integer  "user_id",    index: {name: "index_authorizations_on_user_id"}
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "classifications", force: :cascade do |t|
    t.integer  "project_id",        index: {name: "index_classifications_on_project_id"}
    t.integer  "user_id",           index: {name: "index_classifications_on_user_id"}
    t.integer  "workflow_id",       index: {name: "index_classifications_on_workflow_id"}
    t.jsonb    "annotations",       default: {}
    t.datetime "created_at",        index: {name: "index_classifications_on_created_at"}
    t.datetime "updated_at"
    t.integer  "user_group_id",     index: {name: "index_classifications_on_user_group_id"}
    t.inet     "user_ip"
    t.boolean  "completed",         default: true, null: false
    t.boolean  "gold_standard"
    t.integer  "expert_classifier"
    t.jsonb    "metadata",          default: {},   null: false
    t.integer  "subject_ids",       default: [],                array: true
    t.text     "workflow_version",  index: {name: "index_classifications_on_workflow_version"}
  end

  create_table "collections", force: :cascade do |t|
    t.string   "name"
    t.integer  "project_id",      index: {name: "index_collections_on_project_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "activated_state", default: 0,  null: false
    t.string   "display_name"
    t.boolean  "private"
    t.integer  "lock_version",    default: 0
    t.string   "slug",            default: "", index: {name: "index_collections_on_slug"}
  end

  create_table "collections_subjects", force: :cascade do |t|
    t.integer "subject_id",    null: false
    t.integer "collection_id", null: false, index: {name: "index_collections_subjects_on_collection_id_and_subject_id", with: ["subject_id"], unique: true}
  end

  create_table "media", force: :cascade do |t|
    t.string   "type",          index: {name: "index_media_on_type"}
    t.integer  "linked_id"
    t.string   "linked_type",   index: {name: "index_media_on_linked_type_and_linked_id", with: ["linked_id"]}
    t.string   "content_type"
    t.text     "src"
    t.text     "path_opts",     default: [],                 array: true
    t.boolean  "private",       default: false
    t.boolean  "external_link", default: false
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.jsonb    "metadata"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer  "state",         default: 2,                null: false
    t.integer  "user_group_id", index: {name: "index_memberships_on_user_group_id"}
    t.integer  "user_id",       index: {name: "index_memberships_on_user_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "roles",         default: ["group_member"], null: false, array: true
    t.boolean  "identity",      default: false,            null: false
  end
  add_index "memberships", ["user_id", "identity"], name: "index_memberships_on_user_id_and_identity", unique: true, where: "(identity = true)"

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false, index: {name: "index_oauth_access_grants_on_token", unique: true}
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", index: {name: "index_oauth_access_tokens_on_resource_owner_id"}
    t.integer  "application_id"
    t.string   "token",             null: false, index: {name: "index_oauth_access_tokens_on_token", unique: true}
    t.string   "refresh_token",     index: {name: "index_oauth_access_tokens_on_refresh_token", unique: true}
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",          null: false
    t.string   "uid",           null: false, index: {name: "index_oauth_applications_on_uid", unique: true}
    t.string   "secret",        null: false
    t.text     "redirect_uri",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id",      index: {name: "index_oauth_applications_on_owner_id_and_owner_type", with: ["owner_type"]}
    t.string   "owner_type"
    t.integer  "trust_level",   default: 0,  null: false
    t.string   "default_scope", default: [],              array: true
  end

  create_table "project_contents", force: :cascade do |t|
    t.integer  "project_id",        index: {name: "index_project_contents_on_project_id"}
    t.string   "language"
    t.string   "title",             default: ""
    t.text     "description",       default: ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "introduction",      default: ""
    t.text     "science_case",      default: ""
    t.json     "team_members"
    t.json     "guide"
    t.text     "faq",               default: ""
    t.text     "result",            default: ""
    t.text     "education_content", default: ""
    t.jsonb    "url_labels",        default: {}
  end

  create_table "projects", force: :cascade do |t|
    t.string   "name"
    t.string   "display_name"
    t.integer  "user_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classifications_count", default: 0,     null: false
    t.integer  "activated_state",       default: 0,     null: false
    t.string   "primary_language"
    t.boolean  "private"
    t.integer  "lock_version",          default: 0
    t.jsonb    "configuration"
    t.boolean  "live",                  default: false, null: false, index: {name: "index_projects_on_live"}
    t.jsonb    "urls",                  default: []
    t.boolean  "migrated",              default: false
    t.integer  "classifiers_count",     default: 0
    t.string   "slug",                  default: "", index: {name: "index_projects_on_slug"}
    t.text     "redirect",              default: ""
    t.boolean  "launch_requested",      default: false, index: {name: "index_projects_on_launch_requested", where: "(launch_requested IS TRUE)"}
    t.boolean  "launch_approved",       default: false, index: {name: "index_projects_on_launch_approved"}
    t.boolean  "beta_requested",        default: false, index: {name: "index_projects_on_beta_requested", where: "(beta_requested IS TRUE)"}
    t.boolean  "beta_approved",         default: false, index: {name: "index_projects_on_beta_approved"}
  end

  create_table "recents", force: :cascade do |t|
    t.integer  "classification_id", index: {name: "index_recents_on_classification_id"}
    t.integer  "subject_id",        index: {name: "index_recents_on_subject_id"}
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "set_member_subjects", force: :cascade do |t|
    t.integer  "subject_set_id",       index: {name: "index_set_member_subjects_on_subject_set_id"}
    t.integer  "subject_id",           index: {name: "index_set_member_subjects_on_subject_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "priority"
    t.integer  "lock_version",         default: 0
    t.decimal  "random",               null: false, index: {name: "index_set_member_subjects_on_random"}
    t.integer  "retired_workflow_ids", default: [],              array: true, index: {name: "index_set_member_subjects_on_retired_workflow_ids"}
  end
  add_index "set_member_subjects", ["subject_id", "subject_set_id"], name: "index_set_member_subjects_on_subject_id_and_subject_set_id", unique: true

  create_table "subject_queues", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "workflow_id",            index: {name: "index_subject_queues_on_workflow_id_and_user_id", with: ["user_id"]}
    t.integer  "set_member_subject_ids", default: [], null: false, array: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "lock_version",           default: 0
    t.integer  "subject_set_id",         index: {name: "idx_queues_on_ssid_wid_and_id", with: ["workflow_id", "user_id"], unique: true}
  end

  create_table "subject_sets", force: :cascade do |t|
    t.string   "display_name"
    t.integer  "project_id",                index: {name: "index_subject_sets_on_project_id_and_display_name", with: ["display_name"]}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "set_member_subjects_count", default: 0,  null: false
    t.jsonb    "metadata",                  default: {}
    t.integer  "lock_version",              default: 0
    t.boolean  "expert_set"
  end

  create_table "subject_sets_workflows", force: :cascade do |t|
    t.integer "workflow_id",    index: {name: "index_subject_sets_workflows_on_workflow_id"}
    t.integer "subject_set_id", index: {name: "index_subject_sets_workflows_on_subject_set_id"}
  end
  add_index "subject_sets_workflows", ["workflow_id", "subject_set_id"], name: "index_subject_sets_workflows_on_workflow_id_and_subject_set_id", unique: true

  create_table "subject_workflow_counts", force: :cascade do |t|
    t.integer  "set_member_subject_id", index: {name: "index_subject_workflow_counts_on_set_member_subject_id"}
    t.integer  "workflow_id",           index: {name: "index_subject_workflow_counts_on_workflow_id"}
    t.integer  "classifications_count", default: 0
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  create_table "subjects", force: :cascade do |t|
    t.string   "zooniverse_id",  index: {name: "index_subjects_on_zooniverse_id", unique: true}
    t.jsonb    "metadata",       default: {}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "project_id",     index: {name: "index_subjects_on_project_id"}
    t.boolean  "migrated"
    t.integer  "lock_version",   default: 0
    t.string   "upload_user_id"
  end

  create_table "user_collection_preferences", force: :cascade do |t|
    t.jsonb    "preferences",   default: {}
    t.integer  "user_id",       index: {name: "index_user_collection_preferences_on_user_id"}
    t.integer  "collection_id", index: {name: "index_user_collection_preferences_on_collection_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_groups", force: :cascade do |t|
    t.string   "name",                  index: {name: "index_user_groups_on_name", unique: true, case_sensitive: false}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classifications_count", default: 0,    null: false
    t.integer  "activated_state",       default: 0,    null: false
    t.string   "display_name"
    t.boolean  "private",               default: true, null: false
    t.integer  "lock_version",          default: 0
  end

  create_table "user_project_preferences", force: :cascade do |t|
    t.integer  "user_id",             index: {name: "index_user_project_preferences_on_user_id"}
    t.integer  "project_id",          index: {name: "index_user_project_preferences_on_project_id"}
    t.boolean  "email_communication"
    t.jsonb    "preferences",         default: {}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "activity_count"
  end

  create_table "user_seen_subjects", force: :cascade do |t|
    t.integer  "user_id",     index: {name: "index_user_seen_subjects_on_user_id_and_workflow_id", with: ["workflow_id"]}
    t.integer  "workflow_id", index: {name: "index_user_seen_subjects_on_workflow_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subject_ids", default: [], null: false, array: true
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                       default: "", index: {name: "index_users_on_email", unique: true}
    t.string   "encrypted_password",          default: "",       null: false
    t.string   "reset_password_token",        index: {name: "index_users_on_reset_password_token", unique: true}
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",               default: 0,        null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hash_func",                   default: "bcrypt"
    t.string   "password_salt"
    t.string   "display_name",                index: {name: "index_users_on_display_name", unique: true, case_sensitive: false}
    t.string   "zooniverse_id"
    t.string   "credited_name"
    t.integer  "classifications_count",       default: 0,        null: false
    t.integer  "activated_state",             default: 0,        null: false
    t.string   "languages",                   default: [],       null: false, array: true
    t.boolean  "global_email_communication",  index: {name: "index_users_on_global_email_communication", where: "(global_email_communication IS TRUE)"}
    t.boolean  "project_email_communication"
    t.boolean  "admin",                       default: false,    null: false
    t.boolean  "banned",                      default: false,    null: false
    t.boolean  "migrated",                    default: false
    t.boolean  "valid_email",                 default: true,     null: false
    t.integer  "uploaded_subjects_count",     default: 0
    t.integer  "project_id"
    t.boolean  "beta_email_communication",    index: {name: "index_users_on_beta_email_communication", where: "(beta_email_communication IS TRUE)"}
    t.string   "login",                       null: false, index: {name: "index_users_on_login", unique: true, case_sensitive: false}
  end
  add_index "users", ["display_name"], name: "users_display_name_trgm_index", using: :gist, operator_class: "gist_trgm_ops"

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      null: false, index: {name: "index_versions_on_item_type_and_item_id", with: ["item_id"]}
    t.integer  "item_id",        null: false
    t.string   "event",          null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.text     "object_changes"
  end

  create_table "workflow_contents", force: :cascade do |t|
    t.integer  "workflow_id", index: {name: "index_workflow_contents_on_workflow_id"}
    t.string   "language"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.json     "strings",     default: {}, null: false
  end

  create_table "workflows", force: :cascade do |t|
    t.string   "display_name"
    t.jsonb    "tasks",                             default: {}
    t.integer  "project_id",                        index: {name: "index_workflows_on_project_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classifications_count",             default: 0,     null: false
    t.boolean  "pairwise",                          default: false, null: false
    t.boolean  "grouped",                           default: false, null: false
    t.boolean  "prioritized",                       default: false, null: false
    t.string   "primary_language"
    t.string   "first_task"
    t.integer  "tutorial_subject_id",               index: {name: "index_workflows_on_tutorial_subject_id"}
    t.integer  "lock_version",                      default: 0
    t.integer  "retired_set_member_subjects_count", default: 0
    t.jsonb    "retirement",                        default: {}
  end

  add_foreign_key "recents", "classifications"
  add_foreign_key "recents", "subjects"
  add_foreign_key "subject_sets_workflows", "subject_sets"
  add_foreign_key "subject_sets_workflows", "workflows"
  add_foreign_key "subject_workflow_counts", "set_member_subjects"
  add_foreign_key "subject_workflow_counts", "workflows"
end
