class AddNullsOnCategory < ActiveRecord::Migration
  def self.up
     change_column :categories, :title, :string, :null=>false
     change_column :categories, :position, :integer, :null=>false, :default=>0
  end

  def self.down
     change_column :categories, :title, :string, :null=>true
     change_column :categories, :position, :integer, :null=>true

  end
end
