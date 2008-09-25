class SearchController < ApplicationController

  def index
    @current_tab = "search"
    @posts = nil
    @topics = nil
    
    return unless params['q']
      
    q = process_input(params['q'])
    
    if params[:show]=='p' || params[:show].nil? 
      @posts = Search.find_posts(q, params[:page])
      session[:posts_count] = @posts.total_entries unless @posts.nil?
    end
    if params[:show]=='t' || params[:show].nil? 
      options = nil
      if current_user
        joins = " LEFT JOIN read_topics rp ON rp.topic_id = topics.id AND rp.user_id=#{current_user.id}"
        joins << " LEFT JOIN monitoring_topics mt ON mt.topic_id = topics.id and mt.user_id=#{current_user.id}"
        joins << " LEFT JOIN posts AS p ON p.topic_id = topics.id AND p.user_id=#{current_user.id}" 
        select = ", rp.last_read_post_id as last_read_post, NOT ISNULL(mt.id) as monitored, SIGN(COUNT(p.id)) AS with_me"
        options = {:joins=>joins, :select=>select}
      end
      @topics = Search.find_topics(q, params[:page], options)
      session[:topics_count] = @topics.total_entries unless @topics.nil?
    end
  end
  
  def user_posts
    @user = User.find(params[:id])
    @posts = Post.paginate_by_user_id(@user.id, :page => params[:page], :include=>[:user, :tags], :order => 'posts.created_at DESC')
  end
  
  def ip_posts
    @ip = "#{params[:ip1]}.#{params[:ip2]}.#{params[:ip3]}.#{params[:ip4]}"
    @posts = Post.paginate_by_ip(@ip, :page => params[:page], :include=>[:user, :tags], :order => 'posts.created_at DESC')
  end
  
  def process_input(q)
    @words = q.split(/[\s+]/)
    result = {:words=>[], :const=>[]}
    @words.each do |word|
      word_id = SeIndex.get_word_id(word)
      result[:words] << "#{word_id}" if word_id
    end
    result
  end
  
  def tags
    @tag_ids = params[:tags].split(',').collect{|id| id.to_i}.delete_if{|i| i == 0}
    @tags = Tag.find(@tag_ids)
    
    
    joins = @tag_ids.collect{|id| "INNER JOIN tag_items ti_#{id} ON ti_#{id}.topic_id = topics.id AND ti_#{id}.tag_id = #{id}" }.join(" ")
    select = "topics.*"
    if current_user
      joins << " LEFT JOIN read_topics rp ON rp.topic_id = topics.id AND rp.user_id=#{current_user.id}"
      joins << " LEFT JOIN monitoring_topics mt ON mt.topic_id = topics.id and mt.user_id=#{current_user.id}"
      joins << " LEFT JOIN posts AS p ON p.topic_id = topics.id AND p.user_id=#{current_user.id}" 
      select = "topics.*, rp.last_read_post_id as last_read_post, NOT ISNULL(mt.id) as monitored, SIGN(COUNT(p.id)) AS with_me"
    end
    @topics = Topic.paginate(:all, :page =>params[:page], :per_page=>10,:select=>select, :joins=>joins, :include=>[:tags,:forum], :group=>'topics.id')
    
    @related_tags = []
    @topics.each{|t| @related_tags += t.visible_tags_for?(current_user) }
    @related_tags.uniq!
  end
  
end