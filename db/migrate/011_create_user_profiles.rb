class CreateUserProfiles < ActiveRecord::Migration
  def self.up
    create_table :user_profiles do |t|
      t.column "user_id", :integer, :null => false
      t.column "time_zone", :string, :null => false
      t.text :info, :signature
      t.datetime :birthday
      t.timestamps
    end
  end

  def self.down
    drop_table :user_profiles
  end
end
