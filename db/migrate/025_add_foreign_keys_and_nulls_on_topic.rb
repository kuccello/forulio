require "migration_helpers" 
class AddForeignKeysAndNullsOnTopic < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
     change_column :topics, :forum_id, :integer, :null=>false
     change_column :topics, :user_id, :integer, :null=>false
     change_column :topics, :title, :string, :null=>false
    
     change_column :topics, :posts_count, :integer, :null=>false, :default=>0
     change_column :topics, :views_count, :integer, :null=>false, :default=>0
     change_column :topics, :sticky, :boolean, :null=>false, :default=>false
     
     
     foreign_key(:topics, :forum_id, :forums, {:delete=>'CASCADE'})
     foreign_key(:topics, :user_id, :users, {:delete=>'CASCADE'})
  end

  def self.down
     change_column :topics, :forum_id, :integer, :null=>true
     change_column :topics, :user_id, :integer, :null=>true
     change_column :topics, :title, :string, :null=>true
     
     change_column :topics, :posts_count, :integer, :null=>true
     change_column :topics, :views_count, :integer, :null=>true
     change_column :topics, :sticky, :boolean, :null=>true
     
     drop_foreign_key(:topics, :forum_id)
     drop_foreign_key(:topics, :user_id)
  end
end
