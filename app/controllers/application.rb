# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require "authenticated_system.rb"

class ApplicationController < ActionController::Base

  include SimpleCaptcha::ControllerHelpers 
  
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => '92dccd7743578c357c08957b712a2bb6'
  before_filter :set_timezone  
  before_filter :login_from_cookie
  before_filter :fix_unicode_for_safari
  
  before_filter :check_messages
  before_filter :store_host
  
  before_filter :check_ip
  
  include AuthenticatedSystem
  
  def store_host
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
  end
  
  def check_ip
    bip = BlackIp.find(:first, :conditions=>["ip=?", request.remote_ip])  
  
    if bip && params[:action]!='login'
      flash[:notice] = "Your ip is blocked"[:your_ip_is_blocked]
      session[:user] = nil
      redirect_to :controller=>'user', :action=>'login'
      return 
    end
    true
  end
  

  def set_timezone
  	  require 'forum_config'
      #TODO: Make IP Check
     Time.zone = user? ? current_user.profile.time_zone : Configuration.default_time_zone
  end
  
  # This method checks that the user is not logged in
  # and that the :auth_token cookie is set.
  # If that’s the case the user matching the :auth_token 
  # is searched and the token_expiration verified 
  # the the user is automatically logged in.
  def login_from_cookie
    # set showing headers to true, if it is not yet set
    
    return unless cookies[:auth_token] && session[:user].nil?
    user = User.find_by_remember_token(cookies[:auth_token]) 
    if user && !user.remember_token_expires.nil? && Time.now < user.remember_token_expires 
      session[:user] = user
      # FIXME: last_before_now_login is going to db in current user's soze, not in UTC  
      user.update_attribute('last_before_now_login', user.logged_in_at)
      user.update_attribute('logged_in_at', Time.now)
    end
  end
  
  # Set the notice if a parameter is given, then redirect back
  # to the current controller's +index+ action
  def redirect_to_index(msg = nil)         #:doc:
    flash[:notice] = msg if msg
    redirect_to(:action => 'index')
  end
  
  # automatically and transparently fixes utf-8 bug
  # with Safari when using xmlhttp
  def fix_unicode_for_safari
    if headers["Content-Type"] == "text/html; charset=utf-8" and
      request.env['HTTP_USER_AGENT'].to_s.include? 'AppleWebKit' then
      response.body = response.body.gsub(/([^\x00-\xa0])/u) { |s| "&#x%x;" % $1.unpack('U')[0] }
    end
  end
  # Ajax Functions
  def render_javascript_error_for(object)
    errors = object.errors.full_messages
    alert_text = errors.collect { |error| '-' + error }.join("\n")
    render :layout=>false, :inline => alert_text, :status => 500
  end

  @current_tab
  
  def current_tab
    @current_tab || ""
  end
  
  def logged?
    not current_user.nil?
  end
    
  def is_admin
    logged? and current_user.has_role?("admin")
  end
  
  def is_moderator
    logged? and current_user.has_role?("moderator")
  end
  
  def recognize_uri(uri, absolute = false)
    relative_uri = absolute ? uri[((request.protocol + request.host_with_port).length)..(uri.length - 1)] : uri
    relative_uri = relative_uri[0, relative_uri.index('?') || relative_uri.length]
    ActionController::Routing::Routes.recognize_path(relative_uri) 
  end
  
  def check_messages
    
    if current_user
      @msg = Message.find(:first, :conditions=>["user_id=? and closed < 1", current_user.id], :order=>"id DESC")
    end
  end
end

class FManager
 

  def self.init(session)
    session[:uploaded_files] = {}
  end

  
  def self.add_file(session, post_id, file)
    session[:uploaded_files] ||= {}
    index = post_id.nil? ? "0" : post_id.to_s
    
    session[:uploaded_files][index] ||= []
    session[:uploaded_files][index] << {:id=>file.id, :name=>file.file_name, :content_type=>file.content_type}
    
  end
  
  def self.clear_for_post(session, post_id)
    index = post_id.nil? ? "0" : post_id.to_s
    if session[:uploaded_files] and session[:uploaded_files][index]
      session[:uploaded_files][index] = []
    end
  end
  
  def self.remove_file(session, post_id, id)
    index = post_id.nil? ? "0" : post_id.to_s
    if session[:uploaded_files] and session[:uploaded_files][index]
      session[:uploaded_files][index].delete_if{|f| f[:id].to_i==id.to_i}
    end
  end
  
  def self.load_from_post(session, post)
    session[:uploaded_files][post.id.to_s] ||= []
    uploaded_files = session[:uploaded_files][post.id.to_s]
    post.files.each do |f|
      uploaded_files << {:id=>f.id, :name=>f.file_name, :content_type=>f.content_type}
    end
  end
  
  def self.files_for_post(session, post_id)
    index = post_id.nil? ? "0" : post_id.to_s
    if session[:uploaded_files] and session[:uploaded_files][index]
      return session[:uploaded_files][index]
    end
    []
  end
end
