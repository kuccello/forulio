class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.integer :user_id, :forum_id, :first_post_id, :posts_count
      t.string :title
      t.boolean :sticky
      t.timestamps
    end
  end

  def self.down
    drop_table :topics
  end
end
