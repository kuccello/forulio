#=============================================
# Author: <obondar@gmail.com>
#=============================================

require 'rubygems'
require 'active_support'

module Configuration
  #--------------------------------
  #   Language dependent options
  #--------------------------------
  def self.forum_description
    "<p>" << "Forum with features that everyone use. Ruby on Rails inside."[:description] << "</p><p>Email: forulio&nbsp;(at)&nbsp;gmail&nbsp;(dot)&nbsp;com</p>"
  end
    
  def self.site_name
    "Forulio forum"[:site_name]
  end
  
  def self.default_title
    "tag based forum. Ruby on Rails inside."[:default_title]
  end
  
  def self.footer_slogan
    "Forum to comunicate!"[:footer_slogan]
  end
 
  #--------------------------------
  #    General options
  #--------------------------------
  @@salt = "forulio_salt"
  mattr_accessor :salt
    
  @@url = 'http://forulio.com/'
	mattr_accessor :url
	
	@@redirect_after_login = {:controller=>'home'}
  mattr_accessor :redirect_after_login
  
  @@skip_verify = true
  mattr_accessor :skip_verify
	
	@@redirect_after_logout = {:controller=>'home'}
  mattr_accessor :redirect_after_logout
  
  @@default_time_zone = 'Hawaii'
  mattr_accessor :default_time_zone
  
  @@avatar_size = 150
  mattr_accessor :avatar_size
  
  @@avatar_bg_color = '#DEE7F7'#E4E4E4';
  mattr_accessor :avatar_bg_color
  
  @@from_email = 'forulio@gmail.com';
  mattr_accessor :from_email
  
  @@edit_timeout = 300; #seconds
  mattr_accessor :edit_timeout
  
  @@status_list = [1, 'Newbie'[:status_newbie], 50, 'User'[:status_user]]
  mattr_accessor :status_list
  
  @@languages = {'en-US'=>'English', 'ru-RU'=>"Русский", 'uk-UA'=>'Українська'}
  mattr_accessor :languages
  
  @@max_upload_file_size = 307200
  mattr_accessor :max_upload_file_size
  
end