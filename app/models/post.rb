class Post < ActiveRecord::Base
   validates_presence_of :content, :message=>:content_blank_error["can't be blank"]
   cattr_reader :per_page
   @@per_page = 20
  
   belongs_to :topic
   belongs_to :user
   has_many :tag_items
   has_many :files, :class_name=>'FsFile'
   has_many :tags, :through=>:tag_items
  
   def increment_counters(update_self)
     current_topic = self.topic
     current_topic.last_post_id = self.id
     current_topic.posts_count += 1
     current_topic.save
     current_topic.increment_counters(false)
   end
 
   def decrement_counters(update_self)
     current_topic = self.topic
     current_topic.last_post = Post.find(:first, :conditions=>['topic_id=?', current_topic.id], :order=>'id DESC')
     current_topic.posts_count -= 1
     current_topic.save
     current_topic.decrement_counters(false)
   end
 
  def after_create
    AdminHelper.normalize_user_counters(self.user)
  end
  
  def after_destroy
    AdminHelper.normalize_user_counters(self.user)
  end
  
  def before_destroy
    SeIndex.clear_data_for(self, SeIndex.get_post_model)  
  end
  
  def reindex
    SeIndex.reindex({:all=>false, :instance=>self, :model_id=>SeIndex.get_post_model})
  end
  
  def visible_tags_for?(user)
    v_tags = []
    self.tag_items.each { |ti| v_tags << ti.tag if ti.visible_for?(user) }
    v_tags.uniq
  end
  
  def quick_tags(user)
    tags = Tag.find(:all, :conditions=>["status=?", Tag.status_map[:quick]])
    tags - self.visible_tags_for?(user)
  end
  

end
