class UserController < ApplicationController
  helper :files
  before_filter :login_required, :except=>[:login, :signup, :profile, :reset_password, :list, :send_verification]
  
  skip_filter :check_ip, :only=>[:login]
  
  def list
    @current_tab = "users"
    conditions = nil
    if params[:id] == 'block' && is_moderator
      @current_tab = "block"
      conditions = ["valid_from > ?", Time.now]
    end
    allowed_fields = ['login','created_at', 'posts_count', 'logged_in_at']
    if params[:order] and allowed_fields.include?(params[:order])
      order = params[:order]  
    else
      order = 'login'
    end
    @users = User.paginate :page => params[:page], :conditions=>conditions, :order => '%s %s' % [order, params[:desc] == '1' ? 'DESC' : 'ASC']
  end
  
  def login
    @user = User.new
    @send_verification_to = nil
    if user?
      redirect_to Configuration.redirect_after_login
      return
    end
    if request.post?
    #try to authentificate user
      if session[:user] = User.authenticate(params[:user][:email], params[:user][:password])
        if session[:user].valid_from && session[:user].valid_from > Time.now
          flash[:notice] = "You are blocked by moderator"[:you_are_blocked_by_moderator]
          session[:user] = nil
          return
        end
        if params[:save_login] == "1"
          session[:user].remember_me
          session[:invited_friend] = nil
          cookies[:auth_token] = {
            :value => session[:user].remember_token, 
            :expires => session[:user].remember_token_expires 
          }
        end
        flash[:message] = "Hello %s, what is up?"[:login_welcome] % [session[:user].login]
        if params[:to]!=nil
          redirect_to params[:to]
        else
          redirect_to Configuration.redirect_after_login
        end
      else
        user = User.find(:first, :conditions => ["email = ?", params[:user][:email]])
        if not user.nil? and user.verified == 0
          flash[:warning] = "Your account is not activated yet"[:user_is_not_active]
          @send_verification_to = user
        else
          flash[:warning] = "Email with password do not match"[:login_email_with_password_do_not_match]
        end
        
      end
    end 
  end
  
    
  def signup
    @user = User.new
    if (session[:user] != nil)
      redirect_to :controller=>"home"
      return
    end
    if request.post?
      params[:user][:terms] ||= 'no'
      @user = User.new(params[:user])
      @user.verified = Configuration.skip_verify ? 1 : 0
      @user.new_password = true
      User.transaction do 
       if (@user.save_with_captcha)
        profile = UserProfile.new(params[:user_profile])
        profile.user_id = @user.id
        @user.profile =  profile
        @user.posts_count = 0
        @user.roles << Role.find_by_title('user')
        @user.save
        Notifier.deliver_signup(@user) unless Configuration.skip_verify
        if User.count == 1
          @user.roles << Role.find_by_title('admin')
          @user.save
        end
        if Configuration.skip_verify 
          flash[:notice] = "Your account successfully created. Now you can sign in"[:account_created]  
        else
          flash[:notice] = "Your account successfully created. Verification email has been sent to you with instruction how to activate your acount. "[:account_created_with_verify]  
        end
        redirect_to :action=>'login'
      end
     end
    end
  end
  
  def assign_role
    @roles = Role.find(:all)
    if current_user.has_role?('admin', 'moderator')
      user = User.find(params[:user_id])
      role = Role.find(params[:id])
      if role.title=='admin' and current_user.has_role?('admin')
        user.roles << role
      end
      if role.title!='admin'
        user.roles << role
      end
      user.save
    end
    render :update do |page|
      page.replace_html 'roles_box', :partial=>'edit_roles', :locals=>{:roles=>@roles, :user=>user}
    end
  end
  
  def new_assign_role
    if current_user.has_role?('admin')
      user = User.find(params[:user_id])
      role = Role.new(:title=>params[:role])
      if role.valid?
        user.roles << role
        if user.save
          render :update do |page|
             page.replace_html 'roles_box', :partial=>'edit_roles', :locals=>{:roles=>Role.find(:all), :user=>user}
          end
        else
          render_javascript_error_for(user)        
        end  
      else
        render_javascript_error_for(role)  
      end
    end
  end
  
  def unassign_role
    @roles = Role.find(:all)
    if current_user.has_role?('admin', 'moderator')
      user = User.find(params[:user_id])
      role = Role.find(params[:id])
      if user.roles.length==1
        flash[:notice_roles] = 'User should have at least one role'[:user_should_have_at_least_one_role]
      else
        if role.title=='admin' and current_user.has_role?('admin')
          user.roles.delete(role)
        end
        if role.title!='admin'
          user.roles.delete(role)
        end
        user.save
      end
    end
    render :update do |page|
      page.replace_html 'roles_box', :partial=>'edit_roles', :locals=>{:roles=>@roles, :user=>user}
    end
  end
  
  def remove_role
    return unless is_admin
    role = Role.find(params[:id])
    return if role.title == "admin"
    render :update do |page|
      page << (role.destroy ? "$('role_#{role.id}').parentNode.remove();" : ('alert("%s")' % ["Cann\'t delete role"[:role_delete_error]]))
    end
  end
  
  def logout
    do_logout
    flash[:notice] = "You are logged off now"[:logged_off]
    redirect_to Configuration.redirect_after_logout
  end
  
  #--------------------------------------------------------------
    
    # change password page for user
  def change_password
      @user = current_user
      if request.post?
          @user = session[:user]
          @user.change_password(params[:user][:new_password], params[:user][:password_confirmation])
          if @user.save
            flash[:notice2] = 'Password was successfully changed'[:password_changed]
          end
        render :update do |page|
          page.replace_html 'change_password_box', render(:partial => 'user/change_password')
        end
      end
    end
    
    
  def reset_password
      @user = User.new
      if request.post?
        user = User.find_by_email(params[:user][:email])
        
        if user && user.valid_from > Time.now
          flash[:notice] = "You are blocked by moderator"[:you_are_blocked_by_moderator]
          return
        end
        
        if user.nil?
          flash[:warning] = 'No active user registered with given email'[:no_user_with_specified_email]
          return
        elsif user.verified == 0
          flash[:warning] = 'User with given email is not activated yet'[:cannot_reset_password_for_inactive_user]
          return
        end
        User.transaction do
          key = user.generate_security_token
          url = url_for(:action => 'change_password', :key => key)
          new_password = user.generate_security_token
          user.change_password(new_password)
          if user.save
            Notifier.deliver_forgot_password(user, new_password, url)
            flash[:notice] = "Check your email for instructions how to change password"[:check_email_for_instruction_of_password_changing]
            redirect_to Configuration.redirect_after_logout
          end 
        end 
      end
  end
  
  
  def profile
    
    unless params[:id].nil?
      @user =  User.find(params[:id], :include=>[:profile])
      @user_profile = @user.profile
    else
      @user =  current_user
      @user_profile = current_user.profile unless current_user.nil?
    end
    
    redirect_to(login_path) if @user.nil?
    
    @roles = Role.find(:all) if is_admin
    if request.get? 
      render :action=>'user_profile' unless params[:id].nil?
    end
    if request.post?
      @user_profile.update_attributes(params[:user_profile])
      @user.update_attribute('signature', @user_profile.signature)
      flash[:notice] = "Your account successfully updated."[:account_updated]
    end
  end
  
  def edit_profile
    @user =  User.find(params[:id], :include=>[:profile])
    @user_profile = @user.profile
    if is_admin
        @roles = Role.find(:all)
    end
    if @user.id == current_user.id or current_user.has_role?('admin', 'moderator') #if this is my profile or admin, moderator
      if request.post?
        @user_profile.update_attributes(params[:user_profile])
        @user.update_attribute('signature', @user_profile.signature)
        flash[:notice] = "Account successfully updated."[:account_updated]
      end
      render :action=>'profile'
    else
       redirect_to(:login)  #no access need login with more rights
    end
  end
  
  def update_status
    @user = User.find(params[:id])
    value = params[:value].length == 0 ? nil : HTMLTextUtils.sanitize(params[:value], '')
    if @user.update_attribute('custom_status', value)
        render :text=> @user.custom_status || ApplicationHelper.get_user_status(@user)
    else
        render_javascript_error_for(@user)
    end  
  end
  
  def send_message
    if !params[:message].strip.blank?
      usr = User.find(params[:id])
      Notifier.deliver_private_message(current_user, usr, params[:message])
      render :update do |page|
        page.replace_html 'message_status', "<div class='message'>"<<"Message sent"[:message_sent]<<"</div>"
        page.replace_html 'message_area', "<textarea cols='28' rows='3' name='message'></textarea>"
      end
    else
      render :update do |page|
        page.replace_html 'message_status', "<div class='error'>"<<"Message can not be empty"[:message_can_not_be_empty]<<"</div>"
      end
    end
    
  end
  
  def remove_avatar
    current_profile = current_user.profile
    unless current_profile.image.nil?
      FilesHelper.clear_avatar_cache(current_profile.image)
      current_profile.image = nil
      current_profile.save
    end
    render :update do |page|
      page.replace_html 'uploaded_avatar', user_avatar(current_profile, true)
    end
  end
  # uploads image for current user
  def upload_avatar
      if request.post?
        current_profile = UserProfile.find(params[:profile_id])
        if current_profile.user.id != current_user.id and (not current_user.has_role?('admin', 'moderator'))
          return
        end
        @image = current_profile.image.nil? ? FsImage.new() : current_profile.image
        @image.uploaded_data = params[:fs_image][:uploaded_data]
        @image.uploader_id = current_user.id
        begin
          FsImage.transaction do
            if @image.updated_image and @image.save_with_resize(150, 150)
              current_profile.image_id = @image.id
              current_profile.save
            end  
            FilesHelper.store_avatar_to_cache(@image)
            respond_to_parent {
              render :update do |page|  
                page.replace_html "uploaded_avatar", user_avatar(current_profile, true) 
                page << "clear_image_content();"
                page << "$('upload_div', 'change_link').invoke('toggle');"
              end
            }
          end
        rescue StandardError=>e
          logger.error(e)
          respond_to_parent { render :update do |page|  page.replace_html "uploaded_avatar", "Uploading failed"[:avatar_upload_failed] end }
        end
        FilesHelper.clear_avatar_cache(@image)
      end
    end
  
  def update_role_title
      @role = Role.find(params[:id])
      @role.title = params[:value]
      if @role.save
        render :layout => false, :inline => @role.title
      else
        render_javascript_error_for(@role)
      end
  end
  
  def accept
    if (user?)
      current_user.update_attribute('verified', true)
      redirect_to Configuration.redirect_after_login
    else
      redirect_to login_path
    end
  end
  
  def reject
    if user? and session[:user].verified == 0
        user = session[:user]
        do_logout
        user.destroy
        flash[:warning] = "Account successfully removed."[:user_rejeted]  
    end
    do_logout if session[:user]
    redirect_to login_path
  end
  
  def send_verification
    user = User.find(params[:id])
    Notifier.deliver_signup(user) 
    render :text=>'Verification email has been sent.'[:verification_mail_sent], :layout=>false
  end
  
  def block
    user = User.find(params[:id])
    count_days = params[:user][:valid_from]
    user.update_attribute(:valid_from, count_days.to_i.days.since)
    
    new_date = "Valid date changed to %s"[:valid_date_changed_to] % [user.valid_from.strftime("%Y %m %d")]
    acount_valid = "Account valid from %s"[:account_valid_from] % [user.valid_from.strftime("%Y-%m-%d")]
    render :update do |page|
        page.replace_html 'message_status_user', "<div class='notice'>"<< new_date <<"</div>"
        page.replace_html 'user_valid_from', acount_valid
      end
  end
  
  protected
 
  def do_logout
    session[:user].forget_me if session[:user]
    session[:user] = nil
    cookies.delete :auth_token
  end
end
