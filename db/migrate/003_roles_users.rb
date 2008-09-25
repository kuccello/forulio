class RolesUsers < ActiveRecord::Migration
  def self.up
    create_table "roles_users", :id => false, :force => true do |t|
      t.column "user_id",    :integer,   :limit => 10, :default => 0, :null => false
      t.column "role_id",    :integer,   :limit => 10, :default => 0, :null => false
      t.column "created_at", :datetime
      t.column "updated", :datetime
    end
    add_index "roles_users", ["role_id"], :name => "index_roles_users_on_role_id"
    add_index "roles_users", ["user_id"], :name => "index_roles_users_on_user_id"
  end
  
  def self.down
    drop_table "roles_users"
  end
end