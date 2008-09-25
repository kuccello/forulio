# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20080614123526) do

  create_table "black_ips", :force => true do |t|
    t.string   "ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "title",                    :default => "", :null => false
    t.integer  "position",   :limit => 11, :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", :force => true do |t|
    t.integer  "category_id",  :limit => 11,                 :null => false
    t.integer  "last_post_id", :limit => 11
    t.integer  "posts_count",  :limit => 11, :default => 0,  :null => false
    t.integer  "topics_count", :limit => 11, :default => 0,  :null => false
    t.string   "title",                      :default => "", :null => false
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "forums", ["category_id"], :name => "fk_forums_category_id"

  create_table "fs_files", :force => true do |t|
    t.string   "file_name"
    t.string   "content_type"
    t.string   "type"
    t.integer  "size",         :limit => 11
    t.integer  "uploader_id",  :limit => 11
    t.binary   "content",      :limit => 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "post_id",      :limit => 11
  end

  add_index "fs_files", ["post_id"], :name => "fk_fs_files_post_id"

  create_table "messages", :force => true do |t|
    t.boolean  "closed",                   :default => false
    t.boolean  "read",                     :default => false
    t.integer  "user_id",    :limit => 11
    t.integer  "sender_id",  :limit => 11
    t.text     "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "messages", ["user_id"], :name => "fk_messages_user_id"
  add_index "messages", ["sender_id"], :name => "fk_messages_sender_id"

  create_table "monitoring_topics", :force => true do |t|
    t.integer "user_id",    :limit => 11,                :null => false
    t.integer "topic_id",   :limit => 11,                :null => false
    t.integer "parameters", :limit => 11, :default => 0, :null => false
    t.integer "is_email",   :limit => 11
  end

  add_index "monitoring_topics", ["user_id"], :name => "fk_monitoring_topics_user_id"
  add_index "monitoring_topics", ["topic_id"], :name => "fk_monitoring_topics_topic_id"

  create_table "posts", :force => true do |t|
    t.integer  "topic_id",         :limit => 11, :null => false
    t.integer  "user_id",          :limit => 11, :null => false
    t.integer  "reply_to_post_id", :limit => 11
    t.text     "content",                        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip"
  end

  add_index "posts", ["topic_id"], :name => "fk_posts_topic_id"
  add_index "posts", ["user_id"], :name => "fk_posts_user_id"

  create_table "read_topics", :force => true do |t|
    t.integer "topic_id",          :limit => 11, :null => false
    t.integer "last_read_post_id", :limit => 11, :null => false
    t.integer "user_id",           :limit => 11, :null => false
    t.integer "forum_id",          :limit => 11, :null => false
  end

  add_index "read_topics", ["forum_id"], :name => "fk_read_topics_forum_id"
  add_index "read_topics", ["last_read_post_id"], :name => "fk_read_topics_last_read_post_id"
  add_index "read_topics", ["topic_id"], :name => "fk_read_topics_topic_id"
  add_index "read_topics", ["user_id"], :name => "fk_read_topics_user_id"

  create_table "roles", :force => true do |t|
    t.string   "title",                    :default => "", :null => false
    t.integer  "parent_id",  :limit => 10
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["parent_id"], :name => "index_roles_on_parent_id"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer  "user_id",    :limit => 10, :default => 0, :null => false
    t.integer  "role_id",    :limit => 10, :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated"
  end

  add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
  add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"

  create_table "se_data", :id => false, :force => true do |t|
    t.integer "model_id",  :limit => 11,                :null => false
    t.integer "word_id",   :limit => 11,                :null => false
    t.integer "entity_id", :limit => 11,                :null => false
    t.integer "rank",      :limit => 11, :default => 0, :null => false
  end

  add_index "se_data", ["word_id"], :name => "fk_se_data_word_id"

  create_table "se_models", :force => true do |t|
    t.string  "class_name",               :default => "", :null => false
    t.string  "field_name",               :default => "", :null => false
    t.integer "rank",       :limit => 11, :default => 0,  :null => false
  end

  create_table "se_words", :force => true do |t|
    t.string  "word",               :default => "", :null => false
    t.integer "rank", :limit => 11, :default => 0,  :null => false
  end

  add_index "se_words", ["word"], :name => "words_index", :unique => true

  create_table "sessions", :force => true do |t|
    t.string   "session_id",               :default => "", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id",    :limit => 11
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"
  add_index "sessions", ["user_id"], :name => "fk_sessions_user_id"

  create_table "simple_captcha_data", :force => true do |t|
    t.string   "key",        :limit => 40
    t.string   "value",      :limit => 6
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "tag_items", :id => false, :force => true do |t|
    t.integer "tag_id",   :limit => 11, :null => false
    t.integer "topic_id", :limit => 11, :null => false
    t.integer "post_id",  :limit => 11, :null => false
    t.integer "user_id",  :limit => 11, :null => false
  end

  add_index "tag_items", ["topic_id"], :name => "fk_tag_items_topic_id"
  add_index "tag_items", ["post_id"], :name => "fk_tag_items_post_id"
  add_index "tag_items", ["user_id"], :name => "fk_tag_items_user_id"

  create_table "tags", :force => true do |t|
    t.string   "title",                    :default => "", :null => false
    t.integer  "status",     :limit => 11,                 :null => false
    t.string   "style"
    t.datetime "created_at"
  end

  create_table "topics", :force => true do |t|
    t.integer  "user_id",       :limit => 11,                    :null => false
    t.integer  "forum_id",      :limit => 11,                    :null => false
    t.integer  "first_post_id", :limit => 11
    t.integer  "posts_count",   :limit => 11, :default => 0,     :null => false
    t.string   "title",                       :default => "",    :null => false
    t.boolean  "sticky",                      :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "views_count",   :limit => 11, :default => 0,     :null => false
    t.integer  "last_post_id",  :limit => 11
    t.datetime "expire_at"
  end

  add_index "topics", ["forum_id"], :name => "fk_topics_forum_id"
  add_index "topics", ["user_id"], :name => "fk_topics_user_id"

  create_table "user_profiles", :force => true do |t|
    t.integer  "user_id",                      :limit => 11,                 :null => false
    t.string   "time_zone",                                  :default => "", :null => false
    t.text     "info"
    t.text     "signature"
    t.datetime "birthday"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "image_id",                     :limit => 11
    t.text     "formatted_signature"
    t.integer  "last_read_post_id",            :limit => 11
    t.integer  "monitoring_notification_type", :limit => 11
  end

  create_table "users", :force => true do |t|
    t.string   "login",                  :limit => 80, :default => "", :null => false
    t.string   "salted_password",        :limit => 40, :default => "", :null => false
    t.string   "email",                  :limit => 60, :default => "", :null => false
    t.string   "firstname",              :limit => 40
    t.string   "lastname",               :limit => 40
    t.string   "salt",                   :limit => 40, :default => "", :null => false
    t.integer  "verified",               :limit => 11, :default => 0
    t.string   "security_token",         :limit => 40
    t.datetime "token_expiry"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "logged_in_at"
    t.datetime "remember_token_expires"
    t.string   "remember_token"
    t.integer  "posts_count",            :limit => 11
    t.string   "signature"
    t.string   "custom_status"
    t.datetime "last_before_now_login"
    t.datetime "valid_from"
  end

end
