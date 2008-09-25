class AddTopicClosed < ActiveRecord::Migration
  def self.up
     add_column :topics, :expire_at, :datetime
  end

  def self.down
    remove_column :users, :expire_at
  end
end
