class NetstatCount < Scout::Plugin

  OPTIONS = <<-EOS
  regexp:
    name: ps regular expression
    notes: The regular expression used to find the process to report on
  pid_file:
    name: pid file for process
    notes: Alternatively provide PID file for the process to report on
  port:
    name: port number
    notes: TCP port number to report on
  EOS

  def build_report
    port_number = option("port")

    pid = case
            when option("pid_file")
              File.read(option("pid_file")).to_i
            when option("regexp")
              pid =`ps auxww | egrep '#{option("regexp")}' | grep -v egrep`.split[1].to_i
          end

    netstat_output = `netstat -n -a -p | egrep '(:#{port_number}.*#{pid}/)' `.split("\n")

    netstat_results = Hash.new(0)

    netstat_output.each do |netstat_line|
      state = netstat_line.split[-2]
      netstat_results[state] = netstat_results[state] + 1
    end

    report(netstat_results)
  end
end