require "migration_helpers" 
class AddTags < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    create_table :tags do |t|
      t.string :title, :null=>false
      t.integer :user_id, :null=>false
      t.integer :status, :null=>false, :default=>1
      t.string :style
    end
    foreign_key(:tags, :user_id, :users, {:delete=>'CASCADE'})
    
    create_table(:tag_items, :id=>false) do |t|
      t.integer :tag_id, :topic_id, :post_id, :null=>false
    end

    execute "ALTER TABLE `tag_items` ADD PRIMARY KEY (`tag_id`, `topic_id`, `post_id`)"
    
    foreign_key(:tag_items, :tag_id, :tags, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :topic_id, :topics, {:delete=>'CASCADE'})
    foreign_key(:tag_items, :post_id, :posts, {:delete=>'CASCADE'})
  end

  def self.down
    drop_table :tag_items
    drop_table :tags
  end
end
