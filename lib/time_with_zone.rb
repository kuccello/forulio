
module ActiveSupport
  # A Time-like class that can represent a time in any time zone. Necessary because standard Ruby Time instances are 
  # limited to UTC and the system's ENV['TZ'] zone
  class TimeWithZone
    def self._load(str)
      obj = Marshal.load(str)
      TimeWithZone.new(Marshal.load(obj[0]).utc, Marshal.load(obj[1]), Marshal.load(obj[2]))
    end
    
    def _dump(depth)
      Marshal.dump([Marshal.dump(@utc, -1), Marshal.dump(@time_zone, -1), Marshal.dump(@time, -1)])
    end    
  end
end

