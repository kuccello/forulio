class Message < ActiveRecord::Base
  belongs_to :user
  belongs_to :sender, :class_name=>"User"
  
  validates_presence_of :body, :message=>:body_blank_error["can't be blank"]
  @@per_page = 2
end
