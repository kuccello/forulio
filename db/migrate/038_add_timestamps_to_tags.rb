class AddTimestampsToTags < ActiveRecord::Migration
  def self.up
     add_column :tags, :created_at, :datetime
     execute("UPDATE tags SET created_at=NOW()")
     execute("UPDATE tags SET status=1")
  end

  def self.down
     remove_column :tags, :created_at
  end
end
