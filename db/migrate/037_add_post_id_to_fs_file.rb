require "migration_helpers" 
class AddPostIdToFsFile < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    add_column :fs_files, :post_id, :integer
    foreign_key(:fs_files, :post_id, :posts, {:delete=>'CASCADE'})
  end

  def self.down
    drop_foreign_key(:fs_files, :post_id) 
    remove_column :fs_files, :post_id
  end
end
