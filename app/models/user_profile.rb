class UserProfile < ActiveRecord::Base
    belongs_to :user
    belongs_to :image, :class_name=>'FsImage'
    
    before_save :sanitize_signature
    
    def sanitize_signature
      self.formatted_signature = HTMLTextUtils.format_text self.signature
    end
end
