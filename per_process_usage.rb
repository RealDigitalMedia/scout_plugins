class PerProcessUsage < Scout::Plugin

  OPTIONS=<<-EOS
  regexp:
    name: ps regular expression
    notes: The regular expression used to find the process to report on
  name_prefix:
    name: name prefix
    notes: Text to insert before each "cpu" and "mem"
    default: ""
  EOS

  def build_report
    ENV['lang'] = 'C' # forcing English for parsing
    regular_expression = Regexp.new(option("regexp"))
    name_prefix        = option("name_prefix") || ""

    ps_output    = `ps -eo pcpu,pmem,args -ww`

    ps_data = ps_output.split("\n").select { |line| line =~ regular_expression }.first.to_s.split

    if ps_data.size > 2
      percent_cpu = ps_data[0]
      percent_mem = ps_data[1]

      report({ "#{name_prefix} cpu".lstrip => percent_cpu,
               "#{name_prefix} mem".lstrip => percent_mem} )
    end
  end
end