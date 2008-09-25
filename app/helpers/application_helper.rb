# Methods added to this helper will be available to all templates in the application.
require 'htmlentities'
require 'bbcodeizer'
module ApplicationHelper
  include AuthenticatedSystem
  def logged?
    not current_user.nil?
  end
  
  def formatted_time(d, include_time = true)
    ApplicationHelper.formatted_time(d, include_time)
  end
  
  def self.eql_by_mod(d1, d2, mod)
    val1 = d1.to_i.divmod(mod)[0]
    val2 = d2.to_i.divmod(mod)[0]
    val1 == val2
  end
  
  def self.formatted_time(d, include_time = true)
  	return "" if d.nil?
    now = Time.now
    if eql_by_mod(d, now, 86400)
      date = "Today"[:today] + " "
    elsif eql_by_mod(d, now - 86400, 86400) 
      date = "Yesterday"[:yesterday] + " "
    elsif eql_by_mod(d, now, 604800)
      date_format = "on"[:on_week_day] + " %A " 
      date = d.strftime(date_format)   
    else
      date_format = "%d %B" + (now.year != d.year ? " %Y " : " ")
      date = d.strftime(date_format)   
      date = date[1..date.length] if d.day < 10
    end
    if include_time
      time_format = '%H:%M'
      time = d.strftime(time_format)
      time = time[1..time.length] if d.hour < 10
      date + 'at'[:at_time] + ' ' + time
    else
      date
    end
  end
  
  def user_avatar(profile, update = false)
    if profile.image_id!=nil
      ts = update ? "?ts=#{Time.now().to_i}" : ""
      "<img src='#{avatar_path(profile.image_id, 'jpg')}#{ts}'/>"
    else
      "<img src='#{avatar_path('empty', 'png')}'/>"
    end
  end
  
   def flash_helper
     f_names = [:notice, :warning, :message, :error]
     fl = ""
     for name in f_names
      if flash[name]
        fl = fl + "<div class=\"#{name.to_s}\">#{flash[name]}</div>"
        end
        flash[name] = nil;
     end
     if fl.length > 0
       fl = "<div id='flash_messages'>" + fl + "</div><script> new Effect.Fade('flash_messages', {delay:7});</script>";
     end
     return fl
  end
  
  def html_encode(str, bbencode = false)
    coder = HTMLEntities.new(bbencode ? 'bbcode' : 'xhtml1')
    str = coder.encode(str, :basic)
    str = bbcodeize(str) if bbencode
    str
  end
  
  def html_decode(str)
    coder = HTMLEntities.new
    coder.decode(str)
  end
  
  def is_admin
    logged? and current_user.has_role?("admin")
  end
  
  def is_moderator
    logged? and current_user.has_role?("moderator")
  end
  
  def is_user
    logged? and current_user.has_role?("user")
  end
  
  def css_class_for_age date
    diff = (Time.now.to_i - date.to_i).abs
    case diff
      when 0..600 then 'hot_up_to_10min'
      when 601..1800 then 'hot_up_to_30min'
      when 1801..3600 then 'hot_up_to_60min'
      when 3601..86400 then 'hot_today'
      when 86401..604800 then 'hot_this_week'
      else Time.now.month == date.month ? 'hot_this_month' : 'not_hot'
    end
  end
 
  def show_post_link(post, name, options = {})
    link_to(name, show_post_path(post), options)
  end
  
  def get_tab_css(tab)
    if controller.current_tab == tab
      return "current"
    end
    return ""
  end
  
  @hover_items
 
  def hover_for(id, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    
    html = content_tag(:div, 
            content_tag(:div, render(:partial=>'partials/' + options[:template], :locals=>options[:locals]), :class=>'hover_task_content'),
          :class=>'hover_task', :style=>"display:none")
    html += javascript_tag("new Element.HoverObserver('%s');" % [id]) 
    html
  end
  
  #get admin context
  def remote_context_string
    context = remote_context
    "%s/%s" % [ context[:controller], context[:action] ]
  end
  
  def remote_context
    params[:context]
  end
  
  #get admin context
  def context_string
    context = controller.request.path_parameters
    "%s/%s" % [ context[:controller], context[:action] ]
  end
  
  def get_user_status(user)
    ApplicationHelper.get_user_status(user)
  end
  
  def self.get_user_status(user)
    return user.custom_status unless user.custom_status.nil?
    
    value = user.posts_count 
    status = Configuration.status_list
    
    i = status.length - 1
    while i > 0
      return status.at(i) if value > status.at(i - 1)
      i -= 2
    end
    status.at(1)
  end
  
  def highlight_search_words(str, words)
    res = str
    words.each do |word|
      word = Regexp.escape(word)
      res = res.gsub(/(^|[!"#\$%&'\(\)*+,-.\/:;<=>?\@\[\]_`\{|\}~]|[\s\t\r\n\v\f])(#{word})($|[!"#\$%&'\(\)*+,-.\/:;<=>?\@\[\]_`\{|\}~]|[\s\t\r\n\v\f])/i, '\1<span class="search_sel">\2</span>\3')
      #p word
    end
    res
  end
  
  def current_url_add(data)
    path = request.path_parameters.dup
    path.update(data)
    data.each{|k,v| path.delete_if {|key, value| (key.to_s == k.to_s and v.length == 0) }}
    path
 end
 
 def tag_toggle_uri(tag_id)
   tag_ids = controller.request.path_parameters[:tags].split(',').collect{|id| id.to_i}.delete_if{|i| i == 0} if request.path_parameters[:tags]
   tag_ids = [] if tag_ids.nil?
   
   if tag_ids.include?(tag_id)
     tag_ids = tag_ids - [tag_id]
   else
     tag_ids = tag_ids + [tag_id]
   end
   current_url_add({:tags=>tag_ids.join(','), :page=>[]})
 end
 
 

 
 def show_button str
   res = "<div class='fbutton'>"
   res << "<div class='first'>&nbsp;</div>"
   res << "<div class='middle'>"
   res << str
   res << "</div><div class='last'>&nbsp;</div></div><div class='clear'></div>"
 end
 
end
