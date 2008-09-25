require 'date'
require 'time'
class Symbol
   @lz_default
   @lz_caller
   
   def t
     key = self
     MultiLanguage::Helper.translate_caller(caller[0], "translations", key, nil, key.to_s)
   end

    def [](default)
     @lz_default = default
     @lz_caller = caller[0]
     self
   end
   
   def %(*arguments)
     return self.lz_to_s % arguments if @lz_caller.nil?
     t2 % arguments
   end
   
   alias_method :lz_to_s, :to_s
   def to_s
     return lz_to_s if @lz_caller.nil?
     t2
   end
   
   protected
     def t2
       key = self
       #avoid recursion when calling not own methods
       lz_caller, lz_default= @lz_caller, @lz_default
       @lz_caller, @lz_default = nil, nil
       
       result = MultiLanguage::Helper.translate_caller(lz_caller, "translations", key, nil, lz_default)
       
       @lz_caller, @lz_default= lz_caller, lz_default
       result
     end
end

class String
  alias_method :square_brackets, :[]
  alias_method :plus, :+
  
  def [](*arguments)
    if arguments[0].is_a?(Symbol)
      language = arguments.length > 1 ? arguments[1] : nil
      MultiLanguage::Helper.translate_caller(caller[0], "translations", arguments[0], language, self)
    else
      square_brackets(*arguments)  
    end
  end
  
  def +(value)
    return plus(value.to_s) if !value.nil? and value.is_a?(Symbol)
    plus(value) 
  end
  
end

module MultiLanguage
	module TimeFormat
		private
		L_MONTHNAMES = "January February March April May June July August September October November December"
	  L_DAYNAMES = "Sunday Monday Tuesday Wednesday Thursday Friday Saturday"
	  L_ABBR_MONTHNAMES = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
	  L_ABBR_DAYNAMES = "Sun Mon Tue Wed Thu Fri Sat"
	  
	  @@translate_cache = {}
    public
	  def self.start(language)
	  	hash = {
	  		:MONTHNAMES => MultiLanguage::Helper.translate_caller(nil, "time", :MONTHNAMES, language, L_MONTHNAMES),
		  	:DAYNAMES => MultiLanguage::Helper.translate_caller(nil, "time", :DAYNAMES, language, L_DAYNAMES),
	  		:ABBR_MONTHNAMES => MultiLanguage::Helper.translate_caller(nil, "time", :ABBR_MONTHNAMES, language, L_ABBR_MONTHNAMES),
	  		:ABBR_DAYNAMES => MultiLanguage::Helper.translate_caller(nil, "time", :ABBR_DAYNAMES, language, L_ABBR_DAYNAMES)
	  	}
	  	hash.each {|key, value| 
	  		@@translate_cache[key] = eval("%w(" + value +")") 
	  	}
	  end
	  
    def self.translate(group, index)
	  	return @@translate_cache[group][index]
	end
    
    def self.has_translation?()
      return !@@translate_cache.empty?
    end
	end
end	

class Time
	def emit(e, f) # :nodoc:
    case e
    when Numeric
      sign = %w(+ + -)[e <=> 0]
      e = e.abs
    end

    s = e.to_s

    if f[:s] && f[:p] == '0'
      f[:w] -= 1
    end

    if f[:s] && f[:p] == "\s"
      s[0,0] = sign
    end

    if f[:p] != '-'
      s = s.rjust(f[:w], f[:p])
    end

    if f[:s] && f[:p] != "\s"
      s[0,0] = sign
    end

    s = s.upcase if f[:u]
    s = s.downcase if f[:d]
    s
  end

  def emit_ad(e, w, f) # :nodoc:
    if f[:x]
      f[:u] = true
      f[:d] = false
    end
    f[:p] ||= "\s"
    f[:w] = [f[:w], w].compact.max
    emit(e, f)
  end
	private :emit, :emit_ad
	
	include MultiLanguage::TimeFormat
	alias_method :lz_strftime, :strftime
	def strftime(fmt)
   return lz_strftime(fmt) unless MultiLanguage::TimeFormat.has_translation? 
   fmt.gsub(/%([-_0^#]+)?(\d+)?[EO]?(:{1,3}z|.)/m) do |m|
			f = {}
			s, w, c = $1, $2, $3
			if ['A', 'a', 'B', 'b'].include?(c)
				case c
					when 'A'; emit_ad(MultiLanguage::TimeFormat.translate(:DAYNAMES, wday), 0, f)
					when 'a'; emit_ad(MultiLanguage::TimeFormat.translate(:ABBR_DAYNAMES, wday), 0, f)
					when 'B'; emit_ad(MultiLanguage::TimeFormat.translate(:MONTHNAMES, mon - 1), 0, f)
					when 'b'; emit_ad(MultiLanguage::TimeFormat.translate(:ABBR_MONTHNAMES, mon - 1), 0, f)
				end
			else
				emit_ad(lz_strftime(m), 0, f)
			end
		end
  end
end

