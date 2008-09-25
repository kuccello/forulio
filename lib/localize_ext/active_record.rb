module ActiveRecord
  class Base
    class << self
      alias_method :lz_human_attribute_name, :human_attribute_name
      def human_attribute_name(attr_name)
        lz_caller = "%s/app/models/%s.rb:0:in `human_attribute_name'" % [RAILS_ROOT, self.to_s.underscore]
        MultiLanguage::Helper.translate_caller(lz_caller, "translations", attr_name.to_sym, nil, lz_human_attribute_name(attr_name))
      end  
    end
  end
end