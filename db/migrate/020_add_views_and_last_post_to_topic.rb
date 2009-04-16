class AddViewsAndLastPostToTopic < ActiveRecord::Migration
  def self.up
    add_column :topics, :views_count, :integer
    add_column :topics, :last_post_id, :integer
    add_column :users, :posts_count, :integer
  end

  def self.down
    remove_column :topics, :views_count
    remove_column :topics, :last_post_id
    remove_column :users, :posts_count
  end
end
