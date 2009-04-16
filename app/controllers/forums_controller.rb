class ForumsController < ApplicationController
  def show
    @current_tab = 'forums'
    @forum = Forum.find_by_id(params[:id])
    joins = "AS t"
    select = "t.*"
    if current_user
      joins = " AS t LEFT JOIN read_topics rp ON rp.topic_id = t.id AND rp.user_id=#{current_user.id}"
      joins << " LEFT JOIN monitoring_topics mt ON mt.topic_id = t.id and mt.user_id=#{current_user.id}"
      joins << " LEFT JOIN posts AS p ON p.topic_id = t.id AND p.user_id=#{current_user.id}" 
      select = "t.*, rp.last_read_post_id as last_read_post, NOT ISNULL(mt.id) as monitored, SIGN(COUNT(p.id)) AS with_me"
    end
    conditions=["t.forum_id=?", @forum.id]
    @topics = Topic.paginate :select=>select, :conditions=>conditions, :page => params[:page], :joins=>joins, :order => 'sticky DESC, last_post_id DESC', :group => "t.id"
  end
end
