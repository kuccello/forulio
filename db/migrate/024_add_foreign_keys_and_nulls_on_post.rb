require "migration_helpers" 
class AddForeignKeysAndNullsOnPost < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    change_column :posts, :topic_id, :integer, :null=>false
    change_column :posts, :user_id, :integer, :null=>false
    change_column :posts, :content, :text, :null=>false
    
    foreign_key(:posts, :topic_id, :topics, {:delete=>'CASCADE'})
    foreign_key(:posts, :user_id, :users, {:delete=>'CASCADE'})
  end

  def self.down
    change_column :posts, :topic_id, :integer, :null=>true
    change_column :posts, :user_id, :integer, :null=>true
    change_column :posts, :content, :text, :null=>true
    
    drop_foreign_key(:posts, :topic_id)
    drop_foreign_key(:posts, :user_id)
  end
end
