module MigrationHelpers
  def foreign_key(from_table, from_column, to_table, options)
    constraint_name = "fk_#{from_table}_#{from_column}" 

    ondelete = ("on delete " + options[:delete] unless options[:delete].nil?) || ""
    onupdate = ("on update " + options[:update] unless options[:update].nil?) || ""
    
    execute %{alter table #{from_table}
              add constraint #{constraint_name}
              foreign key (#{from_column})
              references #{to_table}(id) 
              #{ondelete}
              #{onupdate}}
  end
  
  def drop_foreign_key(from_table, from_column)
      constraint_name = "fk_#{from_table}_#{from_column}" 
      execute %{alter table #{from_table}
              drop foreign key #{constraint_name}}
  end
end