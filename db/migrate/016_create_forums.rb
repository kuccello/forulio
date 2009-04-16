class CreateForums < ActiveRecord::Migration
  def self.up
    create_table :forums do |t|
      t.integer :category_id, :last_post_id, :posts_count, :topics_count
      t.string :title, :description
      t.timestamps
    end
  end

  def self.down
    drop_table :forums
  end
end
