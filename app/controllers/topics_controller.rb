class TopicsController < ApplicationController
  before_filter :login_required, :except=>[:show, :new_posts, :show_post]
  before_filter :admin_required, :only =>[:delete]
  def load_title
    render :text=>Topic.find(params[:id]).title
  end
  
  def close
    @topic = Topic.find(params[:id])
    render :update do |page|
      if can_edit_topic @topic 
        @topic.update_attribute('expire_at', Time.now)
        page.redirect_to :action=>'show'
      end
    end
  end
  
  def toggle_sticky
    @topic = Topic.find(params[:id])
    render :update do |page|
      if can_edit_topic @topic 
        @topic.toggle!('sticky')
        page.insert_html :top, 'topic_title', image_tag("sticky.gif") if @topic.sticky 
        page << '$($("topic_title").firstChild).remove();' unless @topic.sticky 
        page << "Topic.setStickyText(%d)" % [@topic.sticky ? 1 : 0]
        #page.redirect_to :action=>'show'
      end
    end
  end
  
  def toggle_monitoring
    @topic = Topic.find(params[:id])
    MonitoringTopic.toogle_monitoring(@topic, current_user, params[:is_email]) unless current_user.nil? and @topic.nil?
    render :partial=>'topics/monitoring', :locals=>{:topic=>@topic}
  end
  
  def stop_monitoring
    @topic = Topic.find(params[:id])
    MonitoringTopic.stop_monitoring(@topic, current_user) unless current_user.nil? and @topic.nil?
    render :nothing=>true
  end
  
  def show
    
    # clear uploaded files list
    FManager.init(session)
    
    topic = Topic.find_by_id(params[:id])
    topic.update_attribute(:views_count, topic.views_count+1)
    
    @topic = Topic.find_by_id(params[:id], :include=>[:forum, :tags])
    
    @forum = @topic.forum
    
    tag_ids = []
    #select tag_ids from params and convert them to integers
    tag_ids = params[:tags].split(',').collect{|id| id.to_i}.delete_if{|i| i == 0} if params[:tags]
    joins = tag_ids.collect{|id| "INNER JOIN tag_items ti_#{id} ON ti_#{id}.post_id = posts.id AND ti_#{id}.tag_id = #{id}" }.join(" ")
    
    @topic_tags = @topic.visible_tags_for?(current_user)
    @tags = @topic_tags.dup.delete_if{|tag| not tag_ids.include?(tag.id) }
        
    @posts = Post.paginate_by_topic_id @topic.id, :page => params[:page], 
      :joins=>joins,
      :order => 'posts.created_at ASC', 
      :include=>[:user, :tags]

    @first_unread_link = nil
    if not current_user.nil? and tag_ids.length == 0  
      old_last_read_post_id = current_user.read_topic(@topic, @posts.last.id)
      if old_last_read_post_id
        first_new_post = @posts.detect {|p| p.id > old_last_read_post_id}
        @first_unread_link = first_new_post ? get_go_to_post_url(first_new_post) : show_post_path(old_last_read_post_id)  
      end
    end
  end
  
  def update_title
     @topic = Topic.find(params[:id])
     if @topic.update_attribute('title', params[:value])
        @topic.reindex
        render :layout => false, :inline => @topic.title
      else
        render_javascript_error_for(@topic)
      end  
  end
    
  def new
    @forum = Forum.find(params[:forum])
    @topic = Topic.new(params[:topic])
    @post = Post.new(params[:post])

    return unless request.xhr? 
    @post.user = current_user
    @topic.user = current_user
    action = params[:topic_action] || ''
    
    render :update do |page|
      if not @topic.valid? or not @post.valid? or action == 'preview'
        @post.created_at = Time.now
        page.replace_html  'preview_topic', render(:partial => 'topics/preview', :locals=>{:post => @post, :topic=>@topic})
        page.visual_effect :Appear,  'preview_topic'
      elsif action == 'save'
        begin
        Topic.transaction do 

          @topic.forum = @forum
          @topic.save

          @post.topic = @topic
          @post.ip = request.remote_ip
          @post.save
          
          @topic.first_post = @post
          @topic.last_post =  @post
          @topic.posts_count = 1
          @topic.views_count = 0
          @topic.save
        end
        current_user.read_topic(@topic, @post.id)
        @topic.reindex
        @post.reindex
        @topic.increment_counters(true)
        flash[:message] = "Topic &quot;%s&quot; was successfully created"[:topic_was_created] % [@topic.title]
        page.redirect_to topic_path(@topic)
        rescue StandardError=>e
          logger.error(e)
          page << "$('preview_topic').hide();"
          page << "alert('%s');" % ["Sorry, your topic can not be saved now. Please try again later"[:topic_can_not_saved_because_of_error]]
        end
      end
    end
  end
  
  def quick_reply
    
    @topic = Topic.find_by_id(params[:topic])
    @post = Post.find_by_id(params[:post])
    return if @topic.nil? or @post.nil?
    
    reply_id = "reply_div_#{@post.id}"
    @posted = Post.new
    render :update do |page|
      unless params[:commit].nil?
        @posted.content = params[:posted][:content]
        @posted.topic_id = params[:topic].to_i
        @posted.reply_to_post_id = params[:post].to_i
        @posted.user_id = current_user.id
        @posted.ip = request.remote_ip
        if @posted.save
          notify_about_new_post(@posted)
          
          @posted.increment_counters(true)
          
          FManager.files_for_post(session, @post.id).each do |file|
            f = FsFile.find(file[:id])
            f.post_id = @posted.id
            f.save
          end
          FManager.clear_for_post(session, @posted.id)
          
          page.replace_html "uploaded_files_#{@post.id}", :partial=>"uploaded_files", :locals=>{:files=>[]} 
          
          post_page = Topic.page_of_post(@post)
          posted_page = Topic.page_of_post(@posted)
          current_user.read_topic(@posted.topic, @posted.id)
          #Insert new row on same page
          inserted = false
          if post_page == posted_page && !request.env["HTTP_REFERER"].nil?
             options = @controller.recognize_uri(request.env["HTTP_REFERER"], true)
             if options[:controller] == "topics"
                page.call "Post.insert", render(:partial => 'topics/post', :locals=>{:post=>@posted, :show_topics=>false})
                page << "Post.scrollTo(#{@posted.id});"
                inserted = true
            end
          end
          #dispaly go to my reply post
          unless inserted
            page.replace_html  reply_id, render(:partial => 'topics/quick_posted', :locals=>{:post => @post, :posted=>@posted, :topic=>@topic}) 
            page.visual_effect :Highlight,  reply_id
            page.visual_effect :Fade,  reply_id, {:delay=>10}
          else
            page.replace_html  reply_id, ""
          end
          @posted.reindex
        else
          #display error
          page.replace_html  reply_id, render(:partial => 'topics/quick_reply', :locals=>{:post => @post, :posted=>@posted, :topic=>@topic})
          page.visual_effect :Highlight,  reply_id, {:duration=>0.5}
        end
      else
        #display reply
        @posted.content = "[quote=\"%s [url=%s][t]wrote[/t][/url]\"]\n" % [@post.user.login, show_post_path(@post)]  + @post.content.strip + "[/quote]"          
        page.replace_html  reply_id, render(:partial => 'topics/quick_reply', :locals=>{:post => @post, :posted=>@posted, :topic=>@topic})
        page.visual_effect :Appear,  reply_id, {:duration=>0.5}
      end
    end
  end
  
  def quick_reply_topic
    @topic = Topic.find_by_id(params[:topic])
    return if @topic.nil?
    current_page = params[:page].nil? ? 1 : params[:page].to_i
    
    reply_id = "reply_div_topic"
    @posted = Post.new
    render :update do |page|
      unless params[:commit].nil?
        @posted.content = params[:posted][:content]
        @posted.topic_id = params[:topic].to_i
        @posted.user_id = current_user.id
        @posted.ip = request.remote_ip
        if @posted.save
          
          notify_about_new_post(@posted)
          
          @posted.increment_counters(true)
          FManager.files_for_post(session, nil).each do |file|
            f = FsFile.find(file[:id])
            f.post_id = @posted.id
            f.save
          end
          
          FManager.clear_for_post(session, nil)
          
          page.replace_html "uploaded_files", :partial=>"uploaded_files", :locals=>{:files=>[]} 
          
          current_user.read_topic(@posted.topic, @posted.id)
          posted_page = Topic.page_of_post(@posted)
          page << 'if($("errorExplanation"))Element.hide("errorExplanation");'
          #Insert new row on same page
          if current_page == posted_page
            page.call "Post.insert", render(:partial => 'topics/post', :locals=>{:post=>@posted, :show_topics=>false})
            page << "$('reply_topic_loader', 'reply_topic_controls').invoke('toggle');"
            page.visual_effect :Fade,  reply_id
          else
            #dispaly go to my reply post
            page.replace_html  'quick_posted_topic', render(:partial => 'topics/quick_posted', :locals=>{:posted=>@posted, :topic=>@topic})
            page.visual_effect :Highlight,  'quick_posted_topic'
            page.visual_effect :Fade,  'quick_posted_topic', {:delay=>10}  
            page.visual_effect :Fade,  reply_id
            
            page << "$('reply_topic_loader', 'reply_topic_controls').invoke('toggle');"
          end
          @posted.reindex
        else
          #display error
          page.replace_html  reply_id, render(:partial => 'topics/quick_reply_topic', :locals=>{:posted=>@posted, :topic=>@topic, :current_page=>current_page})
          page.visual_effect :Highlight,  reply_id
        end
      else
        #display reply
        @posted.content = ""
        page.replace_html  reply_id, render(:partial => 'topics/quick_reply_topic', :locals=>{:posted=>@posted, :topic=>@topic, :current_page=>current_page})
        page.visual_effect :Appear,  reply_id, {:duration=>0.5}
      end
    end
  end

  def delete
    @topic = Topic.find(params[:id])
    render :update do |page| 
         page << (@topic.destroy ? "Topic.remove('#{@topic.id}')" : "alert('%s')") % ["Topic can not be deleted"[:topic_cannot_be_deleted]]
    end
  end
   
  def new_posts
    @current_tab = "new_posts"
    session[:new_type] = params[:new_type] unless params[:new_type].nil?

    session[:new_type] ||= 'since_last_login'
    session[:new_type] = 'all' unless user?
    
    search_params = [params[:page], current_user]
    
    last_before_login = current_user.last_before_now_login || Date.today if current_user
    logged_at = current_user.logged_in_at if current_user
    
    methods = {
      :since_last_login =>[:new_from, last_before_login], 
      :session => [:new_from, logged_at], 
      :with_me => [:unreads, true],
      :all_unread => [:unreads],
      :monitored=>[:unreads_in_monitored],
      :all => [:all_as_new]}
    args = methods.fetch(session[:new_type].to_sym, methods[:all])
    search_method = Topic.method(args.shift)
    search_params += args
    @topics = search_method.call(*search_params) 
  end
  
  def monitored
    @current_tab = 'monitored'
    user = current_user
    joins = " AS t INNER JOIN monitoring_topics mt ON mt.topic_id = t.id and mt.user_id=#{user.id}
                   LEFT JOIN read_topics rp ON rp.topic_id = t.id AND rp.user_id=#{user.id}
                   LEFT JOIN posts AS p ON p.topic_id = t.id AND p.user_id=#{user.id}"
    select='t.*, rp.last_read_post_id AS last_read_post, NOT ISNULL(mt.id) as monitored, SIGN(COUNT(p.id)) AS with_me'
    @topics = Topic.paginate(:all, :select=>select, :group => "t.id", :joins=>joins,  :page => params[:page], :order=>'t.sticky DESC, t.last_post_id DESC')
  end
  
  def upload_file
    
    upl_data = params[:fs_file][:uploaded_data] unless params[:fs_file].nil? 
    post_id=params[:post_id] ? params[:post_id].to_i : nil
    
    if upl_data and upl_data.size > 0 and upl_data.size < Configuration.max_upload_file_size
      @file = FsFile.new()
      @file.uploaded_data = upl_data 
      @file.uploader_id = current_user.id
      if @file.save
        FManager.add_file(session, post_id, @file)
      end
    else
      @err_message = "Please select file with size less then"[:upload_file_size_limit]
    end
    uploaded_files_id, q_file_id  = "uploaded_files", "q_file"
    uploaded_files_id << "_#{params[:post_id]}" unless post_id.nil?
    q_file_id << "_#{params[:post_id]}" unless post_id.nil?
    respond_to_parent {
      render :update do |page|  
        page.replace_html uploaded_files_id, :partial=>"uploaded_files", :locals=>{:files=>FManager.files_for_post(session, post_id), :post_id=>post_id} 
        page.replace_html q_file_id, :partial=>"upload_file_form", :locals=>{:post_id=>post_id}
       end
    }
  end
  
  def delete_file
    post_id=params[:post_id] ? params[:post_id].to_i : nil
    file = FsFile.find_by_id(params[:id])
    
    uploaded_files_id  = "uploaded_files"
    uploaded_files_id << "_#{params[:post_id]}" unless post_id.nil?


    if post_id
      post = Post.find_by_id(post_id)
      FManager.load_from_post(session, post)
    end
    if (file.uploader==current_user or moderator_required) and file.destroy
      FManager.remove_file(session, post_id, file.id)
      render :update do |page|  
          page.replace_html uploaded_files_id, :partial=>"uploaded_files", :locals=>{:files=>FManager.files_for_post(session, post_id), :post_id=>post_id} 
      end
    end
  end
  
  def show_post
    post = Post.find(params[:id]) unless params[:id].nil?
    return if post.nil?
    redirect_to topic_page_path(post.topic, Topic.page_of_post(post)) + "#post" + post.id.to_s
  end
  
  def current_tab
    @current_tab ||= "forums"
  end
  
  def get_go_to_post_url(post)
   page = Topic.page_of_post(post)
   path = (page == 1 and params[:page].nil?) ? topic_path(post.topic) : topic_page_path(post.topic, page)
   path + "#post" + post.id.to_s
 end

 
 
end

