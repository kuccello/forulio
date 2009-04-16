class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.integer :topic_id, :user_id, :reply_to_post_id
      t.text :content
      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end
