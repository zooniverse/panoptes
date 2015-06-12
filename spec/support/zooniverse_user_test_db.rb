class CreateZooniverserUserDatabase < ActiveRecord::Migration
  def connection
    @connection ||= ZooniverseUser.connection
  end

  def change
    create_table "users", :force => true do |t|
      t.string "login", :null => false
      t.string "email", :null => false
      t.string "name"
      t.string "gz1_user_id"
      t.integer "role_id"
      t.string "crypted_password", :null => false
      t.string "password_salt", :null => false
      t.string "persistence_token", :null => false
      t.string "single_access_token", :null => false
      t.string "perishable_token", :null => false
      t.integer "login_count", :default => 0, :null => false
      t.integer "failed_login_count", :default => 0, :null => false
      t.datetime "last_request_at"
      t.datetime "current_login_at"
      t.datetime "last_login_at"
      t.string "current_login_ip"
      t.string "last_login_ip"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "avatar_file_name"
      t.string "avatar_content_type"
      t.integer "avatar_file_size"
      t.datetime "avatar_updated_at"
      t.integer "bulk_user_job_id"
      t.boolean "forum_active", :default => false
      t.string "personal_text"
      t.string "website_title"
      t.string "website_url"
      t.string "location"
      t.text "signature"
      t.boolean "hide_email"
      t.string "display_name"
      t.string "api_key"
      t.string "facebook_user_id"
      t.text "facebook_oauth_token"
      t.string "source"
      t.string "privacy", :default => "0"
      t.datetime "first_email_reminder"
      t.datetime "second_email_reminder"
      t.integer "email_template"
      t.boolean "valid_email"

    end

    add_index "users", ["display_name"], :name => "display_name_index", :length => {"display_name"=>30}
    add_index "users", ["email"], :name => "email_index", :unique => true
    add_index "users", ["login"], :name => "login_index", :unique => true
    add_index "users", ["persistence_token"], :name => "users_persistence_token_index"
    add_index "users", ["single_access_token"], :name => "users_single_access_token_index"
  end
end
