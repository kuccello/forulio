class MonitoringTopic < ActiveRecord::Base
  
  belongs_to :user
  
  def self.monitoring?(topic, user)
    MonitoringTopic.exists?(['user_id=? AND topic_id=?', user.id, topic.id])
  end
  
  def self.toogle_monitoring(topic, user, is_email=false)
    monitoring = MonitoringTopic.find(:first, :conditions=>['user_id=? AND topic_id=?', user.id, topic.id])
    if monitoring.nil?
      MonitoringTopic.create({:user_id=>user.id, :topic_id=>topic.id, :parameters=>0, :is_email=>is_email})
    else
      monitoring.destroy
    end
  end
  
  def self.stop_monitoring(topic, user)
    MonitoringTopic.destroy_all(['user_id=? AND topic_id=?', user.id, topic.id])
  end
end
