class CreateDefaultSecurity < ActiveRecord::Migration
  def self.up
      admin = Role.new(:title=>'admin')
      moderator = Role.new(:title=>'moderator')
      user = Role.new(:title=>'user')
      
      user.save!
      moderator.parent_id = user.id
      moderator.save!
      admin.parent_id = moderator.id
      admin.save!
  end

  def self.down
      Role.delete_all
  end
end
