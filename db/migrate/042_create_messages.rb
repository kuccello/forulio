require "migration_helpers" 
class CreateMessages < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :messages do |t|
      t.boolean :closed, :read, :default=>false
      t.integer :user_id, :sender_id
      t.text :body
      t.timestamps
    end
    foreign_key(:messages, :user_id, :users, {:delete=>'CASCADE'})
    foreign_key(:messages, :sender_id, :users, {:delete=>'CASCADE'})
  end

  def self.down
    drop_table :messages
  end
end
