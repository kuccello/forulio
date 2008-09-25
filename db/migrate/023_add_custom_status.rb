class AddCustomStatus < ActiveRecord::Migration
  def self.up
    add_column :users, :custom_status, :string
  end

  def self.down
    remove_column :users, :custom_status
  end
end
