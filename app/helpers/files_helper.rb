require 'RMagick'
module FilesHelper
  def self.store_avatar_to_cache(file)
      FileUtils.mkdir_p "#{RAILS_ROOT}/public/images/avatars/"
      
      image = Magick::Image::from_blob(file.content).first
    
      white_bg = Magick::Image.new(Configuration.avatar_size, Configuration.avatar_size) {
        self.format = 'JPEG'
        self.background_color = Configuration.avatar_bg_color
      }
      white_bg.composite!(image, Magick::CenterGravity, Magick::OverCompositeOp)  
      
      data = white_bg.to_blob
      
      file_name = "#{RAILS_ROOT}/public/images/avatars/#{file.id}.jpg"
      f = File.open(file_name, 'wb')  
      f.write(data)
      f.close
      
      if (not File.stat(file_name).size?)
        File.unlink(file_name)
      end
      data
  end
  
  def self.clear_avatar_cache(file)
    path = "#{RAILS_ROOT}/public/images/avatars/#{file.id}.jpg"
    if (File.exists?(path))  
      File.unlink(path)
    end
  end
  
end
