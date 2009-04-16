class ModerateController < ApplicationController
  before_filter :moderator_required
  
  def delete_user_posts
    Post.delete_all(["user_id=?", params[:id]])
    AdminHelper.normalize_counters
    render :update do |page|  
        page << "window.location.reload();"
       end
  end
  
  def delete_ip_posts
    @ip = params[:ip]
    Post.delete_all(["ip=?", @ip])
    AdminHelper.normalize_counters
    render :update do |page|  
        page << "window.location.reload();"
       end
  end
  
  def delete_user
    user = User.find(params[:id])
    user.destroy
    flash[:notice] = "User deleted."
    redirect_to users_path
  end
  
  def black
    @ip = BlackIp.create(:ip=>params[:ip])
    render :update do |page|  
        page << "window.location.reload();"
    end
  end
  
  def remove_black
    @ip = BlackIp.find_by_ip(params[:ip])
    @ip.destroy
    render :update do |page|  
        page << "window.location.reload();"
    end
  end
  
  def ips
    @current_tab = 'black_list'
    @ips = BlackIp.find(:all)
  end
end
