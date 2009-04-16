require 'arhelper'
class Tag < ActiveRecord::Base
  has_many :tag_items
  @@per_page = 50
  
  STATUSES = [
    [1, :user, :user_tag["User"]],
    [2, :public, :public_tag["Public"]],
    [3, :quick, :quick_tag["Quick"]],
    [0, :tech, :technical_tag["Technical"]]
  ]
  
  enumerates :status, STATUSES
  
  def public?
    return self.status > Tag.status_map[:user]
  end
  
  def can_be_deleted_by?(user, post)
    return false if user.nil? or post.nil?
    not post.tag_items.detect{|ti| ti.tag_id == self.id and ti.user_id == user.id}.nil?
  end
  
  
end