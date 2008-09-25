class CreateReadTopics < ActiveRecord::Migration
  def self.up
    create_table :read_topics do |t|
      t.integer :topic_id, :last_read_post_id, :user_id
    end
  end

  def self.down
    drop_table :read_topics
  end
end
