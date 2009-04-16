class Notifier < ActionMailer::Base
  helper :application

  
	def forgot_password(user, new_pass, url=nil)
    setup_email(user)

    # Email header info
    @subject += "Forgotten password notification"[:password_reset_notification]
    # Email body substitutions
    @body["name"] = "#{user.login}"
    @body["login"] = "#{user.email}"
		@body["pass"] = "#{new_pass}"
    @body["url"] = url || ""
    @body["app_name"] = Configuration.site_name
		content_type "text/html"
  end

  def private_message(sender, receiver, message)
    @recipients = receiver.email
    @from       = "#{Configuration.site_name} <#{Configuration.from_email}>"
    @subject    = "[#{Configuration.site_name}] Message from #{sender.login}"
    @sent_on    = Time.now
    @headers["Reply-to"] = Configuration.from_email
    @body["receiver"] = receiver
    @body["sender"] = sender
    @body["message"] = message
    content_type "text/html"
  end
  
  def new_post(sender, receiver, post)
    @recipients = receiver.email
    @from       = "#{Configuration.site_name} <#{Configuration.from_email}>"
    @subject    = "[#{Configuration.site_name}] New post in '#{post.topic.title}'"
    @sent_on    = Time.now
    @headers["Reply-to"] = Configuration.from_email
    @body["receiver"] = receiver
    @body["sender"] = sender
    topic = post.topic
    body = "[url=#{topic_page_path(:id=>topic.id, :page=>Topic.page_of_post(post), :only_path =>false)}#post#{post.id}]#{"New post"[:new_post]}[/url]"
    body << " " + "in"[:in] 
    body << " \"#{topic.title}\""
    
    @body["message"] = body
    content_type "text/html"
  end
	
	def signup(user)
    setup_email(user)

    # Email header info
    @subject += "Registration verification "[:registration_verification]
    
    # Email body substitutions
    @body["login"] = user.login
    @body["url"] = url_for(:controller=>"home", :action=>"index")
    @body["accept_url"] = url_for(:controller=>"user", :action=>"accept", :key=>user.generate_security_token)
    @body["reject_url"] = url_for(:controller=>"user", :action=>"reject", :key=>user.generate_security_token)
    @body["app_name"] = Configuration.site_name
    
    content_type "text/html"
  end
  
	
	def setup_email(user)
    @recipients = "#{user.email}"
    @from       = "#{Configuration.site_name} support <#{Configuration.from_email}>"
    @subject    = "[#{Configuration.site_name}] "
    @sent_on    = Time.now
    @headers["Reply-to"] = Configuration.from_email
  end
  
  
end
