class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table "roles", :force => true do |t|
      t.column "title",      :string, :default => "", :null => false
      t.column "parent_id",  :integer, :limit => 10
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
    add_index "roles", ["parent_id"], :name => "index_roles_on_parent_id"
  end
  
  def self.down
    drop_table "roles"
  end
end
