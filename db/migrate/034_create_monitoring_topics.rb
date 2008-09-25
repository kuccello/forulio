require "migration_helpers" 
class CreateMonitoringTopics < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :monitoring_topics do |t|
      t.column :user_id, :integer, :null=>false
      t.column :topic_id, :integer, :null=>false
      t.column :parameters, :integer, :null=>false, :default=>0
    end
    
    foreign_key(:monitoring_topics, :user_id, :users, {:delete=>'CASCADE'})
    foreign_key(:monitoring_topics, :topic_id, :topics, {:delete=>'CASCADE'})
  end

  def self.down
    drop_table :monitoring_topics
  end
end
