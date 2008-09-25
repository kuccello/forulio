require 'yaml'
require 'dispatcher'
require 'localize_ext/core_ext.rb'
require 'localize_ext/action_view.rb'
require 'localize_ext/active_record.rb'
module MultiLanguage
	class Helper
		attr_accessor :translations_cache, :current_language, :logger, :enable_auto_create
		
		def initialize(language)
			self.translations_cache = {}
			self.current_language = language
			self.logger = Logger.new("#{RAILS_ROOT}/log/language_#{language}.log") 
      self.enable_auto_create = false #(RAILS_ENV == 'development')
		end
		
		class << self
			cattr_accessor :instance
			def current_language
				return instance.current_language if instance
				return nil
			end
			#start
      def start(language = 'en-US')
				language ||= 'en-US'
				self.instance = Helper.new(language)
        MultiLanguage::LanguageRules.start(language)
				MultiLanguage::TimeFormat.start(language)
		  end
      #get app relative path
			def app_relative_path(path)
				#raise StandardError.new('path is invalid :' + path) unless path.starts_with?(RAILS_ROOT)
				return ""  unless path.starts_with?(RAILS_ROOT + '/app/')
				path[RAILS_ROOT.length + 4, path.length]
			end
			# Get localized path for given path and language
			def localized_path(path, language = nil)
        		return path if current_language.nil?
				return path unless path.starts_with?(RAILS_ROOT)
				RAILS_ROOT + "/app/localize/#{language || current_language}%s" % [app_relative_path(path)] 
			end
			#Create default empty language file
			def save_language_file(path, object)
				directory_name = File.dirname(path)
				Dir.mkdir(directory_name) unless File.exists?(directory_name)
				File.open(path, 'w' ) do |out|
					YAML.dump(object, out )
				end
				object
		  end
      #load language file
      def load_language_file(path)
        return {} unless File.exists?(path)
        YAML.load_file(path) || {}
      end
			# Get translation for path
			def translations(path, language)
				language_file = localized_path(path, language) + ".yml"
        instance.translations_cache[language_file] ||= load_language_file(language_file)
			end
			#translate by given key
			def translate_caller(caller_file, group, key, language = nil, default = nil)
        return key.to_s if current_language.nil?   
				if caller_file.nil?
					original_path = RAILS_ROOT 
				else
					s = caller_file.scan(/^(.+)\:(\d+)(:in `[_\w\d]+')?$/)
					original_path = s.length > 0 ? s[0][0] : RAILS_ROOT	
			  end
        group_hash = translations(original_path, language).fetch(group) do |_group|
					localized_path = localized_path(original_path, language)
					# if this is local file hash - then we should check global for existing key, otherwise create local file
					if localized_path(RAILS_ROOT, language) != localized_path
						value = translations(RAILS_ROOT, language).fetch(group, {})[key]
            return value unless value.nil?
					end
					localized_path += ".yml"
					# this code is running when there is no local file or group in local file and there is no such group/key pair in global file
					# we should create file with default information
					# or add the group to existing file
					instance.logger.info('Language: "%s/%s" missing in %s.' % [group, key, caller_file])
          return default if (!self.instance.enable_auto_create || default.nil?)
          value = {group=>{key=>default}}
          value.merge!(load_language_file(localized_path)) if File.exists?(localized_path)
          instance.logger.info('Generating "%s"' % [localized_path])
          save_language_file(localized_path, value)[group] || {}  # save full file with currently requested group, key   
				end
        group_hash ||= {}
        group_hash.fetch(key) do |_key|
					# this code is running after group is ensured as created and key not exists
					# we must load language and add key
					instance.logger.info('Language: "%s/%s" missing in %s.' % [group, key, caller_file])
          if self.instance.enable_auto_create 
            localized_path = localized_path(original_path, language) + ".yml"
            
            value = load_language_file(localized_path)
            group_hash[key] = default 
            value[group] = group_hash
            
            instance.logger.info('Generating "%s"' % [localized_path])
            save_language_file(localized_path, value)   
          end
					default
				end
			end
		end
  end
  
  module LanguageRules
    module Extensions
      
    end
    private
    @@current_extension = nil
    #start language rules helper
    def self.start(language)
      class_name = language.upcase().gsub('-', '_');
      file_name = "#{RAILS_ROOT}/lib/localize_ext/%s/extensions.rb" % [language]
      @@current_extension = nil
      
      if not MultiLanguage::LanguageRules::Extensions.constants.include?(class_name) and FileTest.exist?(file_name)
        require file_name
      end
      
      if MultiLanguage::LanguageRules::Extensions.constants.include?(class_name)
        @@current_extension = MultiLanguage::LanguageRules::Extensions.const_get(class_name) 
      end
    end
    
    #get plural key
    def self.plural_key(count, key)
      return key if @@current_extension.nil?
      @@current_extension.plural_key(count, key)
    end
  end
end
