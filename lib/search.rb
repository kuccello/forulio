class Search
  
  def self.method_missing(method, *args)
    find_model = method.to_s.split("_", 2)
    raise StandardError.new('Method not found "%s"' %[method.to_s]) unless find_model[0] == "find"
    raise StandardError.new('Model not found "%s"'  %[find_model[1]]) unless ['posts', 'topics'].include?(find_model[1])
    
    model = Object::const_get(find_model[1].gsub(/s$/, '').capitalize)
    search_params = args[0]
    page = args[1]
    words = search_params[:words].uniq
    
    return nil if words.empty?
    page ||= 1
    
    #se2332.rank + se2323.rank
    select='%s.* , (%s) as rank' % [model.table_name, words.collect {|word_id| "se#{word_id}.rank" }.join("+")]
    
    #INNER JOIN se_data se1 ON p.id = se1.entity_id and se1.word_id=154 AND se1.model_id = '2'
    model_id = SeIndex.__send__("get_%s_model" % [model.to_s.downcase])
    joins_arr = words.collect do |word_id| 
      se = "se#{word_id}"
      "INNER JOIN se_data #{se} ON #{model.table_name}.id = #{se}.entity_id and #{se}.word_id=#{word_id} AND #{se}.model_id = '#{model_id}'"
    end
    
    joins = joins_arr.join(" ")
    group = "#{model.table_name}.id"
    order = "rank DESC, #{model.table_name}.created_at DESC"
    
    if args.length > 2 and args[2].is_a?(Hash)
      options = args[2]
      joins << options[:joins]
      select << options[:select]
    end
    model.paginate :page => page, :per_page=>10, :select=>select, :joins=>joins, :group=>group, :order => order
  end

  def self.respond_to?(method, include_priv = false) #:nodoc:
    case method.to_sym
    when :find_posts, :find_topics
      true
    else
      super(method, include_priv)
    end
  end
end