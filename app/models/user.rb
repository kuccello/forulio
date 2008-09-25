require 'digest/sha1'

class User < ActiveRecord::Base

  @@salt = "forulio"
  
  has_one :profile, :class_name=>"UserProfile"
  has_many :posts
  apply_simple_captcha :message => :capcha_invalid["The secret Image and code were different"], :add_to_base => true
		
	#apply_simple_captcha
  
  # users have a n:m relation to roles
  has_and_belongs_to_many :roles, :uniq => true
  
  validates_acceptance_of :terms,
  	:message => :accept_terms["must be accepted to proceed"], :accept=>'yes'
  
  # We don't want to assign things to roles in bulk assigns.
  attr_protected :roles
    
  attr_accessor :password
  
  # Add accessors for "new_password" property. 
  # This boolean property is set to true when 
  # the password has been set and validation on 
  # this password is required.
  attr_accessor :new_password
    
  # Generate accessors for the password confirmation property.
  attr_accessor :password_confirmation
    
  # Model Validation
    
  validates_presence_of :email, :message=>:email_blank_error["can't be blank"]                    
                      
  # We want a valid email address. Note that the checking done here is very
  # rough. Email adresses are hard to validate now domain names may include
  # language specific characters and user names can be about anything anyway.
  # However, this is not *so* bad since users have to answer on their email
  # to confirm their registration.
  validates_format_of :email, 
                      :with => %r{^([\w\-\.\#\$%&!?*\'=(){}|~_]+)@([0-9a-zA-Z\-\.\#\$%&!?*\'=(){}|~]+)+$},
                      :message => :email_invalid['must be a valid email address.']
                      
  validates_uniqueness_of :email

  validates_presence_of :password, :message => :password_blank_error["can't be blank"], :if => Proc.new { |user| user.new_password?}
  
  # We want to validate the format of the password and only allow alphanumeric
  # and some punctiation characters.
  # The format must only be checked if the password has been set and the record
  # has not been stored yet and it has actually been set at all. Make sure you
  # include this condition in your :if parameter to validates_format_of when
  # overriding the password format validation.
  validates_format_of :password,
                      :with => %r{^[\w\.\- !?(){}|~*_@]+$},
                      :message => :password_invalid['must not contain invalid characters.'],
                      :if => Proc.new { |user| user.new_password?}
    
  # We want the password to have between 6 and 64 characters.
  # The length must only be checked if the password has been set and the record
  # has not been stored yet and it has actually been set at all. Make sure you
  # include this condition in your :if parameter to validates_length_of when
  # overriding the length format validation.
  validates_length_of :password,
                      :within => 6..64,
                      :too_long => :password_to_long['must have between 6 and 64 characters.'],
                      :too_short => :password_to_short['must have between 6 and 64 characters.'],
                      :if => Proc.new { |user| user.new_password?}
    
  validates_confirmation_of :password, :message => :password_confirm_error["should match confirmation"]
                      
  after_validation :crypt_password
    
  # Returns true if the password has been set 
  # after the User has been loaded from the 
  # database and false otherwise
  def new_password?
    @new_password == true
  end
    
  # After saving the object into the database, 
  # the password is not new any more.
  after_save '@new_password = false'
    
  # This method returns all roles assigned to 
  # the given user - including the ones he gets 
  # by being assigned a child role (i.e. the parents).
  def all_roles
    result = Array.new
    for role in self.roles
      result << role.ancestors_and_self
    end
    result.flatten!
    result.uniq!
    return result
  end
    
  # This method returns true if the user is assigned 
  # the role with one of the role titles given as 
  # parameters. False otherwise.
  def has_role?(*role_titles)
    obj = all_roles.detect do |role| 
      role_titles.include?(role.title)
    end
    return !obj.nil?
  end
    
  # Authenticate User by login and password.
  # Check if User with given login and password exist
  # in our database and this User is verified.
  def self.authenticate(email, password)
    user = find(:first, :conditions => ["email = ?", email])
    return nil if (user.nil? or user.verified == 0)
    user = find(:first, :conditions => ["email = ? AND salted_password = ? AND verified = 1", 
      email, User.salted_password(user.salt, User.hashed(password))], :include=>:profile)

    unless user.nil?  
      Time.zone = user.profile.time_zone 
      user.last_before_now_login = user.logged_in_at
      user.logged_in_at = Time.now
      user.save
    end
    user
  end
    
	 def self.authenticate_by_token(token)
    user = find(:first, :conditions => ["security_token = ?", token], :include=>:profile)
    return nil if user.nil? or user.token_expired?
    return nil if false == user.update_expiry
    Time.zone = user.profile.time_zone unless user.nil?  
    return user
  end
  
  def self.online?(user_id)
    t = Time.now.utc
    t_str = t.strftime("%Y-%m-%d %H:%M:%S")
    !User.find(:first, :select=>"u.*", :joins=>"AS u LEFT JOIN sessions AS s ON u.id = s.user_id", :conditions=>"TIMESTAMPDIFF(MINUTE, s.updated_at, '#{t_str}') <= 5 AND u.id='#{user_id}'").nil?
  end
  
  # These create and unset the fields required for 
  # remembering users between browser closes
  def remember_me
    self.remember_token_expires = 2.weeks.from_now
    self.remember_token = Digest::MD5.hexdigest("#{@@salt}--#{self.email}--#{self.remember_token_expires}")
    self.save_with_validation(false)
  end
  
  def forget_me
    self.remember_token_expires = nil
    self.remember_token = nil
    self.save_with_validation(false)
  end
	
	def self.by_email(email)
		user = find(:first, :conditions => ["email = ?", email])
		user
	end

  protected
    
  def self.hashed(str)
    if @@salt == nil
      raise "You must define a :salt"
    end
    return Digest::SHA1.hexdigest("#{@@salt}--#{str}--}")[0..39]
  end
    
  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end
    
  public
    
  def initialize(attributes = nil)
    super(attributes)
    @new_password = false
  end
    
  def token_expired?
    self.security_token and self.token_expiry and (Time.now > self.token_expiry)
  end
    
  def update_expiry
    write_attribute('token_expiry', [self.token_expiry, Time.at(Time.now.to_i + 600 * 1000)].min)
    write_attribute('authenticated_by_token', true)
    #write_attribute("verified", 1)
    update_without_callbacks
  end
    
  def generate_security_token(hours = nil)
    if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
      (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
      return new_security_token(hours)
    else
      return self.security_token
    end
  end
    
  def change_password(pass, confirm = nil)
    self.password = pass
    self.password_confirmation = confirm.nil? ? pass : confirm
    @new_password = true
  end
 
  
  def read_topic(topic, last_post_id)
    r_topic = ReadTopic.find(:first, :conditions=>["user_id=? and topic_id=?", self.id, topic.id])
    old_last_read_post_id = nil
    if r_topic
      if r_topic.last_read_post_id < last_post_id 
        old_last_read_post_id = r_topic.last_read_post_id
        r_topic.update_attribute('last_read_post_id', last_post_id) 
      end
    else
      ReadTopic.create(:user=>self, :topic=>topic, :forum=>topic.forum, :last_read_post_id=>last_post_id)
    end
    return old_last_read_post_id
  end
  
  def self.online_users
    t = Time.now.utc
    t_str = t.strftime("%Y-%m-%d %H:%M:%S")
    users = User.find(:all, :select=>"u.*", 
          :joins=>"as u LEFT JOIN sessions AS s ON s.user_id=u.id ",
          :conditions=>"TIMESTAMPDIFF(MINUTE, s.updated_at, '#{t_str}') <= 5")
    users 
  end
    
  protected
    
  def crypt_password
    if @new_password
      write_attribute("salt", User.hashed("salt-#{Time.now}"))
      write_attribute("salted_password", User.salted_password(salt, User.hashed(@password)))
    end
  end
    
  def new_security_token(hours = nil)
    write_attribute('security_token', User.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
    write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
    update_without_callbacks
    return self.security_token
  end
    
  def token_lifetime(hours = nil)
    if hours.nil?
      48 * 60 * 60
    else
      hours * 60 * 60
    end
  end
  

end
