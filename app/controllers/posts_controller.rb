class PostsController < ApplicationController
  before_filter :login_required

  before_filter :moderator_required, :only=>[:delete]
  
  def edit
    @post = Post.find_by_id(params[:id])
    return if @post.nil? 
  
    content_id = "content_#{@post.id}"
    render :update do |page|
        if not can_edit_post(@post)
          page.insert_html :after, content_id, render(:partial => 'posts/flash', :locals=>{:post => @post, :value=>"You can't edit post anymore!"[:post_editing_expired]})
          page.visual_effect :Highlight,  "post_flash_#{@post.id}", {:duration=>0.5}
          page.visual_effect :Fade,  "post_flash_#{@post.id}", {:delay=>20}  
          page.remove  "edit_#{@post.id}"
        else
          page << "Post.backupContent(#{@post.id});";
          page.replace_html  content_id, render(:partial => 'posts/edit', :locals=>{:post => @post})
          page.visual_effect :Highlight,  content_id, {:duration=>0.5}  
        end
    end
  end
  
  def delete
    post = Post.find_by_id(params[:id])
    return if post.nil?
    render :update do |page|
      if post.topic.first_post!= post
        user = post.user
        forum = post.topic.forum
        post.destroy
        AdminHelper.normalize_user_counters(user)
        AdminHelper.normalize_forum_counters(forum)
        page.call "Post.delete_post", post.id
      else
        page<< "alert('"+"Post can not be deleted. Delete topic instead."[:can_not_delete_first_post]+"');"
      end
    end
  end
  
  def update
   @post = Post.find_by_id(params[:id])
   return if @post.nil? 
   
   render :update do |page|
     unless params[:commit].nil?
        content_id = "content_#{@post.id}"
        if not can_edit_post(@post)
          page.insert_html :after, content_id, render(:partial => 'posts/flash', :locals=>{:post => @post, :value=>"You can't edit post anymore!"[:post_editing_expired]})
          page.visual_effect :Highlight,  "post_flash_#{@post.id}", {:duration=>0.5}
          page.visual_effect :Fade,  "post_flash_#{@post.id}", {:delay=>20}  
        else
          if @post.update_attribute('content', params[:post][:content])
            FManager.clear_for_post(session, @post.id)
            updated_id =  "post_updated_#{@post.id}"
            page.replace_html content_id, render(:partial => 'posts/updated', :locals=>{:post => @post})
            page << "Post.backupContent(#{@post.id}, true);"
            
            page.visual_effect :Highlight,  content_id
            page.visual_effect :Fade,  updated_id, {:delay=>30}  
            
            @post.reindex
          else
            page.replace_html  content_id, render(:partial => 'posts/edit', :locals=>{:post => @post})
            page.visual_effect :Highlight,  content_id, {:duration=>0.5}
          end
        end
     end
   end
 end
 
 def add_tags
    tags = params[:tags].split(",")
    post = Post.find_by_id(params[:id]) unless tags.empty?
    tags.each do |tag_ttl|    
      tag = Tag.find_by_title(tag_ttl)
      
      tag = Tag.create(:title=>tag_ttl, :status=>Tag.status_map[:user]) if tag.nil?
      
      unless post.visible_tags_for?(current_user).include?(tag)
        TagItem.create!(:tag_id=>tag.id, :post_id=>post.id, :topic_id=>post.topic_id, :user_id=>current_user.id)
        post.reload
      end
    end
    
    render :update do |page| 
       page.replace_html "tags_#{post.id}", :partial=>"partials/tags", :locals=>{:tags=>post.visible_tags_for?(current_user), :post=>post}
       page.visual_effect :Highlight,  "add_tags_#{post.id}", {:duration=>0.3}
    end
  end
  
  def remove_tag
    TagItem.delete_all(["post_id=? and tag_id=? and user_id=?", params[:post_id], params[:tag_id], current_user.id])
   
    post = Post.find_by_id(params[:post_id])
    render :update do |page| 
      page.replace_html "tags_#{post.id}", :partial=>"partials/tags", :locals=>{:tags=>post.visible_tags_for?(current_user), :post=>post}
      page.replace_html "add_tags_#{post.id}", :partial=>"posts/add_tags", :locals=>{:post=>post}
    end
  end
end
