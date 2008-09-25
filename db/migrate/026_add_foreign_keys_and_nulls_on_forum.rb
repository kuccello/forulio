require "migration_helpers" 
class AddForeignKeysAndNullsOnForum < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
     change_column :forums, :category_id, :integer, :null=>false
     change_column :forums, :posts_count, :integer, :null=>false, :default=>0
     change_column :forums, :topics_count, :integer, :null=>false, :default=>0
 
     change_column :forums, :title, :string, :null=>false
     
     foreign_key(:forums, :category_id, :categories, {:delete=>'CASCADE'})
    
  end

  def self.down
     change_column :forums, :category_id, :integer, :null=>true
     change_column :forums, :posts_count, :integer, :null=>true
     change_column :forums, :topics_count, :integer, :null=>true
     change_column :forums, :title, :string, :null=>true

     drop_foreign_key(:forums, :category_id) 
  end
end
