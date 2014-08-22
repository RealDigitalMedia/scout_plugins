class ProcessUptime < Scout::Plugin

  OPTIONS = <<-EOS
  regexp:
    name: ps regular expression
    notes: The regular expression used to find the process to report on
  pid_file:
    name: pid file for process
    notes: Alternatively provide PID file for the process to report on
  name_prefix:
    name: name prefix
    notes: Text to insert before each result value
    default: ""
  EOS

  def build_report
    name_prefix = option("name_prefix") || ""

    pid = case
            when option("pid_file")
              File.read(option("pid_file")).to_i
            when option("regexp")
              pid =`ps auxww | egrep '#{option("regexp")}' | grep -v egrep`.split[1].to_i
          end

    uptime = %x{ps -p #{pid} -o etime | tail -1}.chomp

    days_and_time = uptime.split("-")
    if days_and_time.size > 1
      days = days_and_time.shift.to_i
    else
      days = 0
    end

    times = days_and_time.shift.split(":").map { |e| e.to_i }

    if times.size > 2
      hours, minutes, seconds = times
    else
      hours = 0
      minutes, seconds = times
    end

    uptime_seconds = days * 24 * 60 * 60 + hours * 60 * 60 + minutes * 60 + seconds

    report({"#{name_prefix} process uptime".lstrip => uptime_seconds})
  end
end

