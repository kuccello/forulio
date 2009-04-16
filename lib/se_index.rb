require File.dirname(__FILE__) + '/../config/environment'

class SeIndex
  SKIP_WORDS = ['is', 'and', '-', 'a']
  
  INDEX_MODELS = [['Topic', 'title'], ['Post', 'content']]
  class << self
   
    def reindex(options = {:all=>false})
      if options[:all]
        sql = ActiveRecord::Base.connection();
        sql.execute("DELETE FROM se_data")
        INDEX_MODELS.each do |model|
          class_obj = Object::const_get(model[0])
          entires = class_obj.send('find', :all)
          model_id = sql.execute("SELECT id FROM se_models WHERE class_name='#{model[0]}' AND field_name = '#{model[1]}'").fetch_row;
          entires.each do |obj|
            process_text(obj, model_id.to_s)
          end
        end
	  else
		obj = options[:instance]
		model_id = options[:model_id]
		process_text(obj, model_id)
      end
    end
   
    def process_text(obj, model_id)
      sql = ActiveRecord::Base.connection()
      class_name, field_name  = sql.execute("SELECT class_name, field_name FROM se_models WHERE id = '#{model_id}'").fetch_row;
      text = BBCodeizer.bbclear(obj.send(field_name.to_s))
      res = text.split(/[!"#\$%&'\(\)*+,-.\/:;<=>?\@\[\]_`\{|\}~\s\t\r\n\v\f]/)
      res.delete_if {|x| x.empty? || SKIP_WORDS.include?(x) } 

      model_id = clear_data_for([class_name, field_name], obj)

      res.each {|word| process_word(word, obj, model_id)}     
    end
    
    # processing word
    def process_word(word, obj, model_id)

      sql = ActiveRecord::Base.connection()
      # first store words if it is new word for us
      word_id = get_word_id(word)
      
      if word_id == 0
        word = sql.quote(word)
        sql.execute("INSERT INTO se_words (word, rank) VALUES (#{word}, 1)")
        word_id = sql.execute("SELECT id FROM se_words WHERE word=#{word}").fetch_row;
      end
      
      # store word for model and object
      # check if this word is already present
      rank = sql.execute("SELECT rank FROM se_data WHERE model_id='#{model_id}' AND word_id='#{word_id}' AND entity_id='#{obj.id}'").fetch_row;
      if rank
        # if word exists - increase rank
        sql.execute("UPDATE se_data SET rank=rank+1 WHERE model_id='#{model_id}' AND word_id='#{word_id}' AND entity_id='#{obj.id}'")
      else
        # else - add the word
        sql.execute("INSERT INTO se_data (model_id, word_id, entity_id, rank) VALUES ('#{model_id}','#{word_id}', '#{obj.id}', 1)")
      end
    end
    
    
    def get_word_id(word)
      sql = ActiveRecord::Base.connection()
      word = sql.quote(word)
      word_id = sql.execute("SELECT id FROM se_words WHERE word=#{word} AND rank > 0").fetch_row;
      word_id || 0
    end
    
    # clear all indexed data for given object
    # RETURN: model_id
    def clear_data_for(model, obj)
      sql = ActiveRecord::Base.connection()
      # search for model_id
      model_id = sql.execute("SELECT id FROM se_models WHERE class_name='#{model[0]}' AND field_name = '#{model[1]}'").fetch_row;
      return unless model_id
      
      # remove all entires in se_data that belongs to our object
      sql.execute("DELETE FROM se_data where model_id='#{model_id}' AND entity_id='#{obj.id}'")
      model_id
    end
    
    def get_topic_model
      sql = ActiveRecord::Base.connection()
      model_id = sql.execute("SELECT id FROM se_models WHERE class_name='Topic' AND field_name = 'title'").fetch_row;
      "#{model_id}" unless model_id.nil?
    end
    
    def get_post_model
      sql = ActiveRecord::Base.connection()
      model_id = sql.execute("SELECT id FROM se_models WHERE class_name='Post' AND field_name = 'content'").fetch_row;
      "#{model_id}" unless model_id.nil?
    end
  end
end

if __FILE__ == $0
  SeIndex.reindex(:all=>true)
end 