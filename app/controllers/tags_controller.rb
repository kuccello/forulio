class TagsController < ApplicationController
  
  before_filter :moderator_required, :except=>[:index, :autocomplete]
  before_filter :login_required, :except=>[:index]
  
  def index
    user_id = user? ? current_user.id : 0
    conditions = ["tags.status > 1 OR tag_items.user_id = ?", user_id]
    joins = " LEFT JOIN tag_items on tag_items.tag_id = tags.id AND tag_items.user_id = %d" % [user_id]
    @tags = Tag.find(:all, :conditions=>conditions, :joins=>joins, :select=>"tags.*", :group=>"tags.id")
  end
  
  def autocomplete
    tag = params[:tag]
    user_id = user? ? current_user.id : 0
    conditions = ["(tags.status > 1 OR tag_items.user_id = ?) AND tags.title LIKE ?", user_id, tag + '%']
    joins = " LEFT JOIN tag_items on tag_items.tag_id = tags.id AND tag_items.user_id = %d" % [user_id]
    @tags = Tag.find(:all, :conditions=>conditions, :joins=>joins, :select=>"tags.*", :group=>"tags.id")
    render :layout=>false
  end
  
  def manage
    @tags = Tag.paginate(:page=>params[:page], :order=>"title ASC")
  end
  
  def edit
    return if params[:id].nil?
    
    tag = Tag.find(params[:id])
    render :update do |page|
      page.call 'Tag.edit', tag.id, render(:partial => 'tags/edit_tag', :locals=>{:tag=>tag})
    end
  end
  
  def update
    return if params[:id].nil?
    
    tag = Tag.find(params[:id])
    tag.status = params[:tag][:status]
    tag.status_will_change!
    tag.update_attributes(params[:tag])
    render :update do |page|
      page.call 'Tag.update', tag.id, render(:partial => 'tags/tag', :locals=>{:tag=>tag})
    end
  end
  
  def delete
    Tag.destroy(params[:id])
    render :update do |page|
      page.call 'Tag.remove', params[:id]
    end
  end
  
  
  def current_tab
    'tags'
  end
  
end