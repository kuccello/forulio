class Forum < ActiveRecord::Base
    belongs_to :category
    has_many :topics, :order => 'last_post_id DESC'
    belongs_to :last_post ,:class_name=>"Post"
    
    validates_presence_of :title, :message=>:title_blank_error["can't be blank"]
    attr_protected :last_read_post
    
    def unread?(user)
      return false if user.nil?
      return false if self.last_post_id.nil?
      return false if self.last_post_id <= (user.profile.last_read_post_id || 0)
      return self.last_read_post.to_i != self.last_post_id if respond_to?(:last_read_post)
    end
    
 
end
