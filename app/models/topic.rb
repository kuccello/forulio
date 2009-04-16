class Topic < ActiveRecord::Base

  cattr_reader :per_page
  @@per_page = 50
  
  belongs_to :forum
  has_many :posts
  has_many :tag_items
  has_many :tags, :through=>:tag_items
  
  belongs_to :first_post, :class_name=>"Post"
  belongs_to :last_post, :class_name=>'Post'
  belongs_to :user
  

  # dynamic attributes that are filled from other tables and shows last read post, is this topic is monitoring and is this topic has current user's posts. 
  # all attributes are depend on current user
  attr_protected :last_read_post
  attr_protected :monitored
  attr_protected :with_me
  
  validates_presence_of :title,  :message=>:title_blank_error["can't be blank"]
  
  def increment_counters(update_self)
     current_forum = self.forum
     current_forum.topics_count += 1 if update_self
     current_forum.posts_count += 1
     current_forum.last_post_id = self.last_post_id
     current_forum.save
  end
 
  def decrement_counters(update_seft)
     current_forum = self.forum
     current_forum.topics_count -= 1 if update_seft
     current_forum.posts_count -= (update_seft ? self.posts_count : 1)
     topic_with_last_post = Topic.find(:first, :conditions=>['forum_id=?', current_forum.id], :order=>'last_post_id DESC')
     current_forum.last_post = topic_with_last_post.last_post unless topic_with_last_post.nil?
     current_forum.save
  end
 
  def self.page_of_post(post)
    position = Post.count(:conditions=>['topic_id=? AND id < ?', post.topic_id, post.id]) + 1
    page_and_position = position.divmod(Post.per_page)
    page_and_position[0] + (page_and_position[1] > 0 ? 1 : 0)
  end
  
  def closed?
    return false if self.expire_at.nil?
    self.expire_at < Time.now
  end
  
  def destroy
    users_in_topic = []
    Post.find(:all, :conditions=>['topic_id = ?', self.id], :include=>[:user]).each {|post| users_in_topic.push(post.user)}
    users_in_topic = users_in_topic.uniq
    super
    users_in_topic.each {|user| AdminHelper.normalize_user_counters(user) } unless users_in_topic.nil? 
  end
  

  def after_destroy
    decrement_counters(true)
  end
  def before_destroy
    SeIndex.clear_data_for(self, SeIndex.get_topic_model)  
  end
  
  def reindex
	SeIndex.reindex({:all=>false, :instance=>self, :model_id=>SeIndex.get_topic_model})
  end
  
  # check for current user is this topic new for him
  def unread?(user)
    return false if user.nil?
    return false if self.last_post_id <= (user.profile.last_read_post_id || 0)
    return self.last_read_post.to_i != self.last_post_id if respond_to?(:last_read_post)
  end
  
  def last_read_post_id
    return self.last_read_post.to_i if respond_to?(:last_read_post)
    return self.first_post_id
  end
  
  def monitored?
    return self.monitored.to_i == 1 if respond_to?(:monitored)
  end
  
  def with_me?
    return self.with_me.to_i > 0 if respond_to?(:with_me)
  end
  
  def visible_tags_for?(user)
    v_tags = []
    self.tag_items.each { |ti| v_tags << ti.tag if ti.visible_for?(user) }
    v_tags.uniq
  end
  
  
  # all unreaded posts
  def self.unreads(page, user, only_with_me = false)
    page ||= 1
    user_last_post = user.profile.last_read_post_id || 0
    join_type = only_with_me ? "INNER" : "LEFT"
    joins = " AS t #{join_type} JOIN posts AS p ON p.topic_id = t.id AND p.user_id=#{user.id}" 
    joins << " LEFT JOIN read_topics rp ON rp.topic_id = t.id AND rp.user_id=#{user.id}"
    joins << " LEFT JOIN monitoring_topics mt ON mt.topic_id = t.id and mt.user_id=#{user.id} "

    conditions = " (rp.last_read_post_id != t.last_post_id OR rp.last_read_post_id IS NULL)" 
    conditions << " AND (t.last_post_id > #{user_last_post})" 
    
    select='t.*, rp.last_read_post_id AS last_read_post, SIGN(COUNT(p.id)) AS with_me, NOT ISNULL(mt.id) as monitored'
    Topic.paginate(:all, :select=>select, :group => "t.id", :joins=>joins,  :page => page, :order=>'t.sticky DESC, t.last_post_id DESC', :conditions=>conditions)
  end
  
  
  # all unreaded posts in monitored topics
  def self.unreads_in_monitored(page, user)
    page ||= 1
    user_last_post = user.profile.last_read_post_id || 0
    joins = " AS t INNER JOIN monitoring_topics mt ON mt.topic_id = t.id and mt.user_id=#{user.id}
                   LEFT JOIN read_topics rp ON rp.topic_id = t.id AND rp.user_id=#{user.id}
                   LEFT JOIN posts AS p ON p.topic_id = t.id AND p.user_id=#{user.id}"
    conditions = " (rp.last_read_post_id != t.last_post_id  OR rp.last_read_post_id IS NULL) AND t.last_post_id > #{user_last_post}" 
    select='t.*, rp.last_read_post_id AS last_read_post, 1 AS monitored, SIGN(COUNT(p.id)) AS with_me'
    Topic.paginate(:all, :select=>select, :group => "t.id", :joins=>joins,  :page => page, :order=>'t.sticky DESC, t.last_post_id DESC', :conditions=>conditions)
  end
  
  def self.all_as_new(page, user)
    page ||= 1
    select='t.*, '
    select << (user.nil? ? "0" : " rp.last_read_post_id") + " AS last_read_post, "
    select << (user.nil? ? "0" : " NOT ISNULL(mt.id) ") + " AS monitored," 
    select << (user.nil? ? "0" : " SIGN(COUNT(p.id)) ") + " AS with_me"

    joins = " AS t LEFT JOIN posts AS p ON p.topic_id = t.id " 
    joins << " AND p.user_id=#{user.id} " unless user.nil?
    joins << " LEFT JOIN read_topics rp ON rp.topic_id = t.id AND rp.user_id=#{user.id}" unless  user.nil?
    joins << " LEFT JOIN monitoring_topics mt ON mt.topic_id = t.id and mt.user_id=#{user.id}" unless  user.nil?
    Topic.paginate(:all, :select=>select, :group => "t.id", :joins=>joins,  :page => page, :order=>'t.sticky DESC, t.last_post_id DESC')
  end
  
  def self.new_from(page, user, time)
    page ||= 1
    user_last_post = user.profile.last_read_post_id || 0
    select='t.*, rp.last_read_post_id AS last_read_post, NOT ISNULL(mt.id) AS monitored, SIGN(COUNT(p.id)) as with_me'
    joins = " AS t LEFT JOIN posts AS p ON p.topic_id=t.id AND p.user_id=#{user.id} 
                   LEFT JOIN read_topics rp ON rp.topic_id = t.id AND rp.user_id=#{user.id}
                   LEFT JOIN monitoring_topics mt ON mt.topic_id = t.id and mt.user_id=#{user.id}"
    conditions = " '#{time.to_s}' <= p.created_at"
    conditions << " AND (rp.last_read_post_id != t.last_post_id OR rp.last_read_post_id IS NULL )"
    conditions << " AND t.last_post_id > #{user_last_post}"
    Topic.paginate(:all, :select=>select, :group => "t.id", :joins=>joins,  :page => page, :order=>'t.sticky DESC, t.last_post_id DESC', :conditions=>conditions)
  end
  
end
