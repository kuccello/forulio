require "migration_helpers" 
class AddForumToReadTopic < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    ReadTopic.delete_all
    add_column :read_topics, :forum_id, :integer, :null=>false
    change_column :read_topics, :topic_id, :integer, :null=>false
    change_column :read_topics, :user_id, :integer, :null=>false
    change_column :read_topics, :last_read_post_id, :integer, :null=>false
    
    foreign_key(:read_topics, :forum_id, :forums, {:delete=>'CASCADE'})
    foreign_key(:read_topics, :last_read_post_id, :posts, {:delete=>'CASCADE'})
    foreign_key(:read_topics, :topic_id, :topics, {:delete=>'CASCADE'})
    foreign_key(:read_topics, :user_id, :users, {:delete=>'CASCADE'})
  end

  def self.down
    drop_foreign_key(:read_topics, :forum_id) 
    drop_foreign_key(:read_topics, :topic_id) 
    drop_foreign_key(:read_topics, :last_read_post_id) 
    remove_column :read_topics, :forum_id
  end
end
