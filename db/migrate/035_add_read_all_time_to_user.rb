class AddReadAllTimeToUser < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :last_read_post_id, :integer
    add_column :user_profiles, :monitoring_notification_type, :integer
  end

  def self.down
    remove_column :user_profiles, :last_read_post_id
    remove_column :user_profiles, :monitoring_notification_type
  end
end
