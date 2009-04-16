class TagItem < ActiveRecord::Base
  belongs_to :topic
  belongs_to :post
  belongs_to :tag
  
   def visible_for?(user)
    return true if tag.public? 
    return false if user.nil?
    return tag.status == Tag.status_map[:user] && user.id == self.user_id
  end
end