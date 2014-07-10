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

ActiveRecord::Schema.define(version: 20140710111625) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "classifications", force: true do |t|
    t.integer  "set_member_subject_id"
    t.integer  "project_id"
    t.integer  "user_id"
    t.integer  "workflow_id"
    t.json     "annotations"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_group_id"
    t.index ["project_id"], :name => "index_classifications_on_project_id"
    t.index ["set_member_subject_id"], :name => "index_classifications_on_set_member_subject_id"
    t.index ["user_id"], :name => "index_classifications_on_user_id"
    t.index ["workflow_id"], :name => "index_classifications_on_workflow_id"
  end

  create_table "collections", force: true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner_type"
    t.integer  "activated_state", default: 0, null: false
    t.string   "visibility"
    t.string   "display_name"
    t.index ["owner_id"], :name => "index_collections_on_owner_id"
    t.index ["project_id"], :name => "index_collections_on_project_id"
  end

  create_table "collections_subjects", id: false, force: true do |t|
    t.integer "subject_id",    null: false
    t.integer "collection_id", null: false
  end

  create_table "memberships", force: true do |t|
    t.integer  "state"
    t.integer  "user_group_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_group_id"], :name => "index_memberships_on_user_group_id"
    t.index ["user_id"], :name => "index_memberships_on_user_id"
  end

  create_table "oauth_access_grants", force: true do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
    t.index ["token"], :name => "index_oauth_access_grants_on_token", :unique => true
  end

  create_table "oauth_access_tokens", force: true do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
    t.index ["refresh_token"], :name => "index_oauth_access_tokens_on_refresh_token", :unique => true
    t.index ["resource_owner_id"], :name => "index_oauth_access_tokens_on_resource_owner_id"
    t.index ["token"], :name => "index_oauth_access_tokens_on_token", :unique => true
  end

  create_table "oauth_applications", force: true do |t|
    t.string   "name",         null: false
    t.string   "uid",          null: false
    t.string   "secret",       null: false
    t.text     "redirect_uri", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.index ["owner_id", "owner_type"], :name => "index_oauth_applications_on_owner_id_and_owner_type"
    t.index ["uid"], :name => "index_oauth_applications_on_uid", :unique => true
  end

  create_table "project_contents", force: true do |t|
    t.integer  "project_id"
    t.string   "language"
    t.string   "title"
    t.text     "description"
    t.json     "pages"
    t.json     "example_strings"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["project_id"], :name => "index_project_contents_on_project_id"
  end

  create_table "projects", force: true do |t|
    t.string   "name"
    t.string   "display_name"
    t.integer  "user_count"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner_type"
    t.integer  "classifications_count", default: 0,     null: false
    t.integer  "activated_state",       default: 0,     null: false
    t.string   "visibility",            default: "dev", null: false
    t.string   "primary_language"
    t.index ["name"], :name => "index_projects_on_name", :unique => true
    t.index ["owner_id"], :name => "index_projects_on_owner_id"
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "resource_type", "resource_id"], :name => "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], :name => "index_roles_on_name"
  end

  create_table "set_member_subjects", force: true do |t|
    t.integer  "state"
    t.integer  "subject_set_id"
    t.integer  "subject_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classifications_count", default: 0, null: false
    t.index ["subject_id"], :name => "index_set_member_subjects_on_subject_id"
    t.index ["subject_set_id"], :name => "index_set_member_subjects_on_subject_set_id"
  end

  create_table "subject_sets", force: true do |t|
    t.string   "name"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "set_member_subjects_count", default: 0, null: false
    t.index ["project_id"], :name => "index_subject_sets_on_project_id"
  end

  create_table "subject_sets_workflows", id: false, force: true do |t|
    t.integer "subject_set_id", null: false
    t.integer "workflow_id",    null: false
  end

  create_table "subjects", force: true do |t|
    t.string   "zooniverse_id"
    t.json     "metadata"
    t.json     "locations"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.integer  "project_id"
    t.string   "owner_type"
    t.index ["owner_id"], :name => "index_subjects_on_owner_id"
    t.index ["project_id"], :name => "index_subjects_on_project_id"
    t.index ["zooniverse_id"], :name => "index_subjects_on_zooniverse_id", :unique => true
  end

  create_table "uri_names", force: true do |t|
    t.string   "name"
    t.string   "resource_type"
    t.integer  "resource_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], :name => "index_uri_names_on_name", :unique => true, :case_sensitive => false
  end

  create_table "user_groups", force: true do |t|
    t.string   "display_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classifications_count", default: 0, null: false
    t.integer  "activated_state",       default: 0, null: false
  end

  create_table "user_seen_subjects", force: true do |t|
    t.integer  "user_id"
    t.integer  "workflow_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "subject_ids", array: true
    t.index ["user_id", "workflow_id"], :name => "index_user_seen_subjects_on_user_id_and_workflow_id"
    t.index ["user_id"], :name => "index_user_seen_subjects_on_user_id"
    t.index ["workflow_id"], :name => "index_user_seen_subjects_on_workflow_id"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: ""
    t.string   "encrypted_password",     default: "",       null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,        null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login",                                     null: false
    t.string   "hash_func",              default: "bcrypt"
    t.string   "password_salt"
    t.string   "display_name"
    t.string   "zooniverse_id"
    t.string   "credited_name"
    t.integer  "classifications_count",  default: 0,        null: false
    t.integer  "activated_state",        default: 0,        null: false
    t.string   "languages",              default: [],       null: false, array: true
    t.string   "provider"
    t.string   "uid"
    t.index ["email"], :name => "index_users_on_email", :unique => true
    t.index ["login"], :name => "index_users_on_login", :unique => true
    t.index ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true
  end

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["user_id", "role_id"], :name => "index_users_roles_on_user_id_and_role_id"
  end

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], :name => "index_versions_on_item_type_and_item_id"
  end

  create_table "workflows", force: true do |t|
    t.string   "name"
    t.json     "tasks"
    t.integer  "project_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "classifications_count", default: 0,     null: false
    t.boolean  "pairwise",              default: false, null: false
    t.boolean  "grouped",               default: false, null: false
    t.boolean  "prioritized",           default: false, null: false
    t.index ["project_id"], :name => "index_workflows_on_project_id"
  end

end
