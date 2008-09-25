class AddImageIdToUserProfile < ActiveRecord::Migration
  def self.up
      add_column :user_profiles, :image_id, :integer
  end

  def self.down
      remove_column :user_profiles, :image_id
  end
end
