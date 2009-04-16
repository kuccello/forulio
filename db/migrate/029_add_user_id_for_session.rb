require "migration_helpers" 
class AddUserIdForSession < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    add_column :sessions, :user_id, :integer
    foreign_key(:sessions, :user_id, :users, {:delete=>'CASCADE'})
  end

  def self.down
    remove_column :sessions, :user_id
    drop_foreign_key(:sessions, :user_id) 
  end
end
