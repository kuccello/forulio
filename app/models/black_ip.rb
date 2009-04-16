class BlackIp < ActiveRecord::Base
  validates_uniqueness_of :ip, :message=>:ip_not_unique["should be unique"]
end
