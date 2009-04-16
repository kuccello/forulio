class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table "users", :force => true do |t|
      t.column "login",           :string,   :limit => 80, :default => "", :null => false
      t.column "salted_password", :string,   :limit => 40, :default => "", :null => false
      t.column "email",           :string,   :limit => 60, :default => "", :null => false
      t.column "firstname",       :string,   :limit => 40
      t.column "lastname",        :string,   :limit => 40
      t.column "salt",            :string,   :limit => 40, :default => "", :null => false
      t.column "verified",        :integer,                :default => 0
      t.column "security_token",  :string,   :limit => 40
      t.column "token_expiry",    :datetime
      t.column "created_at",      :datetime
      t.column "updated_at",      :datetime
      t.column "logged_in_at",    :datetime
    end
  end
  
  def self.down
    drop_table "users"
  end
end
