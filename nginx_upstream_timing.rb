class NginxUpstreamTiming < Scout::Plugin
  needs 'descriptive_statistics'

  OPTIONS = <<-EOS
  log_path:
    name: Log path
    notes: Full path to the the log file
  term_1:
    name: Term 1
    notes: Computes times for lines matching this expression
  prefix_1:
    name: Prefix 1
    notes: Prefix for this metric
  term_2:
    name: Term 2
    notes: Computes times for lines matching this expression
  prefix_2:
    name: Prefix 2
    notes: Prefix for this metric
  term_3:
    name: Term 3
    notes: Computes times for lines matching this expression
  prefix_3:
    name: Prefix 3
    notes: Prefix for this metric
  term_3:
    name: Term 3
    notes: Computes times for lines matching this expression
  prefix_3:
    name: Prefix 3
    notes: Prefix for this metric
  term_4:
    name: Term 4
    notes: Computes times for lines matching this expression
  prefix_4:
    name: Prefix 4
    notes: Prefix for this metric
  term_5:
    name: Term 5
    notes: Computes times for lines matching this expression
  prefix_5:
    name: Prefix 5
    notes: Prefix for this metric
  send_error_if_no_log:
    attributes: advanced
    default: 1
    notes: 1=yes
  use_sudo:
    attributes: advanced
    default: 0
    notes: 1=use sudo. In order to use the sudo option, your scout user will need to have passwordless sudo privileges.
  EOS

  def init
    if option('use_sudo').to_i == 1
      @sudo_cmd = "sudo "
    else
      @sudo_cmd = ""
    end

    @log_file_path = option("log_path").to_s.strip
    if @log_file_path.empty?
      return error( "Please provide a path to the log file." )
    end

    `#{@sudo_cmd}test -e #{@log_file_path}`

    unless $?.success?
      error("Could not find the log file", "The log file could not be found at: #{@log_file_path}. Please ensure the full path is correct and your user has permissions to access the log file.") if option("send_error_if_no_log") == "1"
      return
    end

    nil
  end

  def float_parse(string)
    Float(string)
  rescue ArgumentError, TypeError
    nil
  end

  def build_report
    return if init()

    metrics = {}

    last_bytes     = memory(:last_bytes) || :no_last_bytes
    current_length = `#{@sudo_cmd}wc -c #{@log_file_path}`.split(' ')[0].to_i

    matches = {}
    5.times.each do |index|
      term_option = "term_#{index}"

      term   = option(term_option)
      prefix = option("prefix_#{index}") || term_option

      matches[Regexp.new(term)] = { prefix: prefix, values: [] } if term
    end

    # don't run it the first time
    if (last_bytes != :no_last_bytes)
      read_length = current_length - last_bytes

      # Check to see if this file was rotated. This occurs when the +current_length+ is less than
      # the +last_run+. Don't return a count if this occured
      if read_length > 0
        # finds new content from +last_bytes+ to the end of the file, then just extracts from the recorded
        # +read_length+. This ignores new lines that are added after finding the +current_length+. Those lines
        # will be read on the next run.
        command = %{#{@sudo_cmd}tail -c +#{last_bytes+1} #{@log_file_path} | head -c #{read_length}}
        puts "Running command: #{command.inspect}"

        IO.popen(command) do |io|
          io.each do |line|
            line.chomp!

            fields = line.split

            # field -2 is the upstream response time
            # field 12 would be response size
            upstream_time = float_parse(fields[-2])
            next unless upstream_time

            matches.each do |term, details|
              details[:values] << upstream_time if line =~ term
            end
          end

          matches.each do |term, details|
            prefix = details[:prefix]
            values = details[:values]

            count = values.size

            # Avoids a computation issue with mean (fails if array is empty)
            values = [0] if count == 0

            metrics.merge!("#{prefix}_upstream_time_95_percentile" => values.percentile(95),
                           "#{prefix}_upstream_time_stddev"        => values.standard_deviation,
                           "#{prefix}_upstream_time_mean"          => values.mean,
                           "#{prefix}_count"                       => values.size)
          end
        end
      end

      report(metrics)
    end

    puts "Remembering length of #{current_length.inspect}"
    remember(:last_bytes, current_length)
  end
end

