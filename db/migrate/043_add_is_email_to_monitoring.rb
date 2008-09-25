class AddIsEmailToMonitoring < ActiveRecord::Migration
  def self.up
    add_column :monitoring_topics, :is_email, :integer
  end

  def self.down
    remove_column :monitoring_topics, :is_email
  end
end
