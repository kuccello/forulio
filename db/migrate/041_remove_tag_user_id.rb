require "migration_helpers" 
class RemoveTagUserId < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    drop_foreign_key(:tags, :user_id)
    remove_column :tags, :user_id
  end

  def self.down
    add_column :tags, :user_id
    foreign_key(:tags, :user_id, :users, {:delete=>'CASCADE'})
    execute('UPDATE tag_items, tags SET tags.user_id = tag_items.user_id WHERE tag_items.tag_id = tags.id')
    change_column :tags, :user_id, :null=>false
  end
end
