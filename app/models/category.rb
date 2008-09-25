class Category < ActiveRecord::Base
  has_many :forums
  validates_presence_of  :title, :message=>:title_blank_error["can't be blank"]
  
  def after_destroy
    AdminHelper.normalize_counters
  end
  
  
  def forums_with_unread_id(user)
    joins = ""
    select = "forums.*"
    if user
      joins = " LEFT JOIN read_topics rp ON rp.forum_id = forums.id AND rp.user_id=#{user.id}"
      select = "forums.*, MAX(rp.last_read_post_id) AS last_read_post"
    end
    Forum.find(:all, :conditions=>['category_id=?', self.id], :joins=>joins, :select=>select, :group=>'forums.id', :order=>'forums.id')
  end
end
