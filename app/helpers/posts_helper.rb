module PostsHelper
  include TopicsHelper
  
  def can_edit_post(post)
    return false unless logged?
    return false if post.topic.closed?
    return true if is_admin or is_moderator
    current_user.id == post.user_id and not edit_expired(post)
  end
  
  def edit_expired(post)
    diff = Time.now - post.created_at
    diff > Configuration.edit_timeout
  end
  
  def can_reply_post(post)
    can_reply_topic(post.topic)
  end
  
end
