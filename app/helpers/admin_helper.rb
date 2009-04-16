module AdminHelper
  
  def self.normalize_counters
    Forum.transaction do
      Forum.find(:all, :include=>:topics).each { |forum|  self.normalize_forum_counters(forum) }    
    end
    User.transaction do
      User.find(:all, :include=>:posts).each {|user| self.normalize_user_counters(user)} 
    end
  end
  
   def self.normalize_category_counters(category_id)
    Forum.transaction do
      Forum.find(:all, :include=>:topics, :conditions=>['category_id=?', category_id]).each { |forum|  self.normalize_forum_counters(forum) }    
    end
    User.transaction do
      User.find(:all, :include=>:posts).each {|user| self.normalize_user_counters(user)} 
    end
  end
  
  def self.normalize_user_counters(user)
    user.update_attribute('posts_count', user.posts.length)
  end
  
  def self.normalize_forum_counters(forum)
    forum.last_post_id, forum.topics_count, forum.posts_count = nil, 0, 0
    forum.topics.each do |topic|
      self.normalize_topic_counters(topic)  
      forum.topics_count += 1
      forum.posts_count +=  topic.posts_count
      forum.last_post_id = topic.last_post_id if forum.last_post_id.nil? or topic.last_post_id > forum.last_post_id
    end
    
    forum.save!
  end
  
  def self.normalize_topic_counters(topic)
    topic.posts_count = topic.posts.count
    topic.last_post = topic.posts.max {|p1, p2| p1.id <=>  p2.id }
    topic.save!
  end
  
end
