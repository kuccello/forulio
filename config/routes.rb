ActionController::Routing::Routes.draw do |map|

  

  map.resources :forums
  map.resources :topics

  map.connect '', :controller=>"home"
  
  map.simple_captcha '/simple_captcha/:action', :controller => 'simple_captcha'
  map.signup 'signup/', :controller=>"user", :action=>"signup"
  map.logout 'logout/', :controller=>"user", :action=>"logout"
  map.login 'login/', :controller=>"user", :action=>"login"
  map.avatar 'images/avatars/:id.:format', :controller=>'files', :action=>'avatar'
  
  map.file      'files/:id/:name',                      :controller=>'files',    :action => 'download'
  map.file1     'files/:id/:name.:f1',                  :controller=>'files',    :action => 'download'
  map.file2     'files/:id/:name.:f1.:f2',              :controller=>'files',    :action => 'download'
  
  map.edit_profile 'profile/:id/edit', :controller=>"user", :action=>"edit_profile"
  map.profile 'profile/:id', :controller=>"user", :action=>"profile"
  
  map.quick_reply 'quick_reply/:topic/:post',:controller=>'topics', :action=>'quick_reply'
  map.quick_reply_topic 'quick_reply_topic/:topic/:page',:controller=>'topics', :action=>'quick_reply_topic'
  
  map.category 'category/:id', :controller=>"home", :action=>'index'
  
  map.upload_file 'upload_file', :controller=>"topics", :action=>'upload_file' 
  map.connect 'delete_file/:id', :controller=>"topics", :action=>'delete_file' 
  map.delete_file 'delete_file/:id/:post_id', :controller=>"topics", :action=>'delete_file' 
  
  map.new_topic  'topics/new/:forum',:controller=>'topics', :action=>'new'
  map.topic_update_title 'topics/update_title/:id', :controller=>"topics", :action=>'update_title'
  map.topic_load_title 'topics/load_title/:id', :controller=>"topics", :action=>'load_title'
   
  map.connect 'forums/:id/page/:page', :controller=>"forums", :action=>'show' #this cause all forumns actions not defined before will go to show
  
  map.topic_page 'topics/:id/page/:page', :controller=>"topics", :action=>'show' #this cause all topics actions not defined before will go to show
  map.show_post 'show_post/:id', :controller=>"topics", :action=>'show_post' 
  map.connect 'topics/:id/tags/:tags', :controller=>"topics", :action=>'show' 
  map.connect 'topics/:id/page/:page/tags/:tags', :controller=>"topics", :action=>'show' 
  
  map.connect 'user_posts/:id/page/:page/', :controller=>"search", :action=>'user_posts' 
  map.user_posts 'user_posts/:id', :controller=>"search", :action=>'user_posts' 
  map.ip_posts 'ip_posts/:ip1.:ip2.:ip3.:ip4', :controller=>"search", :action=>'ip_posts' 
  
  map.tags_filter 'search/tags/:tags', :controller=>'search', :action=>'tags' 
  map.connect 'search/tags', :controller=>'search', :action=>'tags' 
  map.connect 'search/tags/page/:page/:tags', :controller=>'search', :action=>'tags' 
  
  
  map.new_posts 'new_posts/:new_type', :controller=>"topics", :action=>'new_posts'
  map.connect 'new_posts', :controller=>"topics", :action=>'new_posts'
  
  map.users 'users', :controller=>"user", :action=>'list'
  map.search 'search', :controller=>"search", :action=>'index'
  map.connect 'monitoring', :controller=>"topics", :action=>'monitored'
  
  map.send_message 'send_message/:id', :controller=>"messages", :action=>"send_message"
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
