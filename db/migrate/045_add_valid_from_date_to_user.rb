class AddValidFromDateToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :valid_from, :datetime
    User.update_all(['valid_from=?', Time.today])
  end

  def self.down
    remove_column :users, :valid_from
  end
end
