class HomeController < ApplicationController
   def index
     if params[:mark_as_read] && current_user
       current_user.profile.update_attribute(:last_read_post_id, Post.find(:first, :order=>'id DESC').id) rescue nil
     end
     
     @current_tab = 'forums'
     conditions=[]
     if params[:id]
       conditions = ["id=?", params[:id]]
     end
     @categories = Category.find(:all, :order=>'position ASC', :conditions=>conditions)
   end
end
