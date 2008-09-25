require "migration_helpers" 
class TagItemsUserId < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    add_column :tag_items,:user_id,:integer 
    execute('UPDATE tag_items, tags SET tag_items.user_id = tags.user_id WHERE tag_items.tag_id = tags.id')
    change_column :tag_items,:user_id,:integer, :null=>false
    
    foreign_key(:tag_items, :user_id, :users, {:delete=>'CASCADE'})
  end

  def self.down
    drop_foreign_key(:tag_items, :user_id)
    remove_column :tag_items,:user_id
  end
end
