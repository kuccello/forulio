module TopicsHelper
  
  def can_edit_topic(topic)
    return false unless logged?
    return false if topic.closed?
    is_admin or is_moderator
  end
  
  def can_reply_topic(topic)
    logged? and not topic.closed?
  end
  
  def get_topic_title_css(topic)
    res = ''
    res << 'topic_unread ' if topic.unread?(current_user)
    res << 'topic_monitored ' if topic.monitored?
    res
  end
  
  def notify_about_new_post(post)
   topic = post.topic
   monitorings = MonitoringTopic.find(:all, :conditions=>['topic_id=?', topic.id])
   monitorings.each do |monitoring|
     #next if monitoring.user == post.user 
     is_online = User.online?(monitoring.user_id)
     # if user online - send internal message only
     if is_online
       message = Message.new
       message.user_id = monitoring.user_id
       message.sender_id = post.user.id
       format = "[size=0.7]%s[/size] [url=%s]%s[/url] [sup][color=Red][size=0.7]+1[/size][/color][/sup]"
       message.body =  format % [post.created_at.strftime("%H:%M"), show_post_path(post), topic.title]
       message.save
     elsif monitoring.is_email
       Notifier.deliver_new_post(post.user, monitoring.user, post)
     end
   end
 end
end
