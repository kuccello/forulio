class AddFormattedSignature < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :formatted_signature, :text
  end

  def self.down
     remove_column :user_profiles, :formatted_signature
  end
end
