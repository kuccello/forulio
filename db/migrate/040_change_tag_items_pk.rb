require "migration_helpers" 
class ChangeTagItemsPk < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table(:temp, :id=>false) do |t|
      t.integer :tag_id, :topic_id, :post_id, :user_id, :null=>false
    end
    execute "INSERT INTO temp SELECT * FROM tag_items"
    
    drop_table :tag_items
    create_table(:tag_items, :id=>false) do |t|
      t.integer :tag_id, :topic_id, :post_id, :user_id, :null=>false
    end
    execute "ALTER TABLE `tag_items` ADD PRIMARY KEY (`tag_id`, `topic_id`, `post_id`, `user_id`)"
    
    foreign_key(:tag_items, :tag_id, :tags, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :topic_id, :topics, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :post_id, :posts, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :user_id, :users, {:delete=>'CASCADE'})
    
    execute "INSERT INTO tag_items SELECT * FROM temp"
    
    drop_table :temp
  end

  def self.down
    create_table(:temp, :id=>false) do |t|
      t.integer :tag_id, :topic_id, :post_id, :user_id, :null=>false
    end
    execute "INSERT INTO temp SELECT * FROM tag_items"
    
    drop_table :tag_items
    create_table(:tag_items, :id=>false) do |t|
      t.integer :tag_id, :topic_id, :post_id, :user_id, :null=>false
    end
    execute "ALTER TABLE `tag_items` ADD PRIMARY KEY (`tag_id`, `topic_id`, `post_id`)"
    
    foreign_key(:tag_items, :tag_id, :tags, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :topic_id, :topics, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :post_id, :posts, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :user_id, :users, {:delete=>'CASCADE'})
     
    execute "INSERT INTO tag_items SELECT * FROM temp"
    
    drop_table :temp
  end
end
