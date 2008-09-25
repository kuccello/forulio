class AddLastBeforeCurrentLoggedDate < ActiveRecord::Migration
  def self.up
    add_column :users, :last_before_now_login, :datetime
  end

  def self.down
     remove_column :users, :last_before_now_login
  end
end
