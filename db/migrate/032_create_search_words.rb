require "migration_helpers" 
class CreateSearchWords < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :se_words do |t|
      t.column :word, :string, :null => false  
      t.column :rank, :integer, :null => false, :default=>0
    end
    add_index :se_words, :word, {:name => "words_index", :unique => true}
    
    create_table :se_models do |t|
      t.column :class_name, :string, :null => false
      t.column :field_name, :string, :null => false
      t.column :rank, :integer, :null => false, :default=>0
    end
    execute "INSERT INTO `se_models` (`class_name`, `field_name`, `rank`) VALUES ('Topic', 'title', 100)"
    execute "INSERT INTO `se_models` (`class_name`, `field_name`, `rank`) VALUES ('Post', 'content', 10)"

    create_table(:se_data, :id=>false)  do |t|
      t.column :model_id, :integer, :null => false
      t.column :word_id, :integer, :null => false
      t.column :entity_id, :integer, :null => false
      t.column :rank, :integer, :null => false, :default=>0
    end
    execute "ALTER TABLE `se_data` ADD PRIMARY KEY (`model_id`, `word_id`, `entity_id`)"
    foreign_key(:se_data, :model_id, :se_models, {:delete=>'CASCADE'})
    foreign_key(:se_data, :word_id, :se_words, {:delete=>'CASCADE'})
  end

  def self.down
     drop_table :se_data
     drop_table :se_models
     drop_table :se_words
  end
end