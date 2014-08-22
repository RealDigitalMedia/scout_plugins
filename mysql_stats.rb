class MysqlStatistics < Scout::Plugin
  ENTRIES = %w{Innodb_row_lock_time Innodb_row_lock_waits Created_tmp_disk_tables Created_tmp_files Created_tmp_tables Table_locks_immediate Table_locks_waited Sort_merge_passes Sort_range Sort_rows Sort_scan Slow_queries Select_full_join Select_full_range_join Select_range Select_range_check Select_scan}

  OPTIONS=<<-EOS
  user:
    name: MySQL username
    notes: Specify the username to connect with
    default: root
  password:
    name: MySQL password
    notes: Specify the password to connect with
    attributes: password
  host:
    name: MySQL host
    notes: Specify something other than 'localhost' to connect via TCP
    default: localhost
  port:
    name: MySQL port
    notes: Specify the port to connect to MySQL with (if nonstandard)
  socket:
    name: MySQL socket
    notes: Specify the location of the MySQL socket
  entries:
    name: Entries to process
    notes: space separated entries to process
  EOS

  needs "mysql"

  # Returns nil if an empty string
  def get_option(opt_name)
    val = option(opt_name)
    return (val.is_a?(String) and val.strip == '') ? nil : val
  end

  def build_report
    user     = get_option(:user) || 'root'
    password = get_option(:password)
    host     = get_option(:host)
    port     = get_option(:port)
    socket   = get_option(:socket)
    entries  = get_option(:entries).to_s.split.map(&:downcase)

    mysql = Mysql.connect(host, user, password, nil, (port.nil? ? nil : port.to_i), socket)

    result = mysql.query(%{SHOW /*!50002 GLOBAL */ STATUS})
    result.each do |row|
      key   = row.first
      value = row.last.to_i
      if entries.include?(key.downcase)
        counter(key, value, :per => :second)
      end
    end
    result.free

    result = mysql.query(%{SHOW /*!50000 ENGINE*/ INNODB STATUS})
    columns = result.each do |row|
      columns = row.last.split("\n")

      columns.each do |column|
        report("free_pages"     => column.split.last.to_i) if column =~ /Free buffers/      && entries.include?("free_pages")
        report("database_pages" => column.split.last.to_i) if column =~ /Database pages/    && entries.include?("database_pages")
        report("modified_pages" => column.split.last.to_i) if column =~ /Modified db pages/ && entries.include?("modified_pages")
        report("pool_size"      => column.split.last.to_i) if column =~ /Buffer pool size/  && entries.include?("pool_size")
      end
    end
    result.free
  end
end

