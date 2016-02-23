class MysqlConnectionStatistics < Scout::Plugin
  ENTRIES = %w(Com_insert Com_select Com_update Com_delete)

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
  users:
    name: Users to report
    notes: Comma separated list of users.
  EOS
  needs "mysql"

  def build_report
    # get_option returns nil if the option value is blank
    user     = option(:user) || 'root'
    password = option(:password)
    host     = option(:host)
    port     = option(:port)
    socket   = option(:socket)
    users    = option(:users).split(",").map { |u| u.delete(' ') }

    mysql = Mysql.connect(host, user, password, nil, (port.nil? ? nil : port.to_i), socket)

    mysql_connection_stats = {}
    users.each { |user| mysql_connection_stats["#{user}_Query"] = mysql_connection_stats["#{user}_Sleep"] = 0 }

    result = mysql.query('SHOW PROCESSLIST;')
    result.each do |row|
      user, state = row.to_a.values_at(1,4)
      key = "#{user}_#{state}"
      puts key
      next unless users.include?(user)
      mysql_connection_stats[key] = mysql_connection_stats.fetch(key, 0) + 1
      puts "Added 1"
    end
    result.free

    report(mysql_connection_stats)
  end
end