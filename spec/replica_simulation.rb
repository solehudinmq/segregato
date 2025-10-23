def copy_sqlite_data(source_db_path, destination_db_path)
  source_db = SQLite3::Database.new(source_db_path)

  destination_db = SQLite3::Database.new(destination_db_path)

  destination_db.transaction

  begin
    tables = source_db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    
    tables.each do |(table_name)|
      columns_info = source_db.table_info(table_name)
      
      columns_definition = columns_info.map do |col|
        name = col['name']
        type = col['type']
        notnull = col['notnull'].to_i == 1 ? 'NOT NULL' : ''
        pk = col['pk'].to_i == 1 ? 'PRIMARY KEY' : ''
        
        "#{name} #{type} #{notnull} #{pk}".strip.squeeze(' ')
      end.join(', ')

      create_table_sql = "CREATE TABLE IF NOT EXISTS #{table_name} (#{columns_definition})"
      
      destination_db.execute(create_table_sql)
      
      data = source_db.execute("SELECT * FROM #{table_name}")
      
      if data.any?
        column_names = columns_info.map { |col| col['name'] }.join(', ')
        
        placeholders = Array.new(columns_info.size, '?').join(', ')
        
        insert_sql = "INSERT INTO #{table_name} (#{column_names}) VALUES (#{placeholders})"
        
        destination_db.prepare(insert_sql) do |stmt|
          data.each do |row|
            stmt.execute(*row)
          end
        end
      end
    end

    destination_db.commit
  rescue SQLite3::Exception => e
    destination_db.rollback
  ensure
    source_db.close if source_db
    destination_db.close if destination_db
  end
end