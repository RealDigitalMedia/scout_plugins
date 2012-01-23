class OpenFileCount < Scout::Plugin

  OPTIONS = <<-EOS
  regexp:
    name: ps regular expression
    notes: The regular expression used to find the process to report on
  pid_file:
    name: pid file for process
    notes: Alternatively provide PID file for the process to report on
  EOS

  def build_report
    pid = case
            when option("pid_file")
              File.read(option("pid_file")).to_i
            when option("regexp")
              pid =`ps auxww | egrep '#{option("regexp")}' | grep -v egrep`.split[1].to_i
          end

    open_file_count = `lsof -p #{pid} | wc -l`

    report({:open_file_count => open_file_count})
  end
end