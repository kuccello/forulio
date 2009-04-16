class Admin::ForumController < ApplicationController
  before_filter :admin_required
  
  def new
    @forum = Forum.new
    @forum.category_id = params[:category]
    render :update do |page|
      page.call "Forum.insert", render(:partial => 'new', :locals=>{:forum => @forum}), @forum.category_id
    end
  end
  
  def create
    @forum = Forum.new(params[:forum])
    @forum.posts_count = 0
    @forum.topics_count = 0
    update_result(@forum, params[:update_id])
  end
  
  def update
    @forum = Forum.find(params[:id])
    @forum.update_attributes(params[:forum])
    update_result(@forum)
  end
  
  def edit
     @forum = Forum.find(params[:id])
     render :update do |page|
          page.call("Forum.update", @forum.id, render(:partial => 'edit', :locals=>{:forum => @forum}), 1)
     end
  end
  
  def delete
    @forum = Forum.find(params[:id])
    render :update do |page| 
         page << (@forum.destroy ? "Forum.remove(#{@forum.id})" : "alert('%s')") % ["Forum can not be deleted"[:forum_can_not_be_deleted]]
    end
  end
  
  protected
  def update_result( forum, client_id = nil)
    render :update do |page|
      if forum.save
          page.call("Forum.update", client_id || forum.id, render(:partial => 'home/forum', :locals=>{:forum => forum}), 0)
      else
          page.call("forum.update", client_id || forum.id, render(:partial => 'new', :locals=>{:forum => forum}), 0)
      end
    end
  end
end
