class SunJStat < Scout::Plugin

  OPTIONS = <<-EOS
  regexp:
    name: ps regular expression
    notes: The regular expression used to find the process to report on
  pid_file:
    name: pid file for JVM
    notes: Alternatively provide PID file for the process to report on
  jstats_path:
    name: Path to jstats executable
    default: ${JAVA_HOME}/bin/jstat
  name_prefix:
    name: name prefix
    notes: Text to insert before each result value
    default: ""
  EOS

  def build_report
    name_prefix = option("name_prefix") || ""
    jstats_path = option("jstats_path") || "#{ENV["JAVA_HOME"]}/bin/jstat"

    pid = case
            when option("pid_file")
              File.read(option("pid_file")).to_i
            when option("regexp")
              pid =`ps auxww | egrep '#{option("regexp")}' | grep -v egrep`.split[1].to_i
          end

    stats = `#{jstats_path} -gc #{pid}`.split("\n").last.split

    surivor_0_capacity = stats[0].to_f
    surivor_1_capacity = stats[1].to_f
    survivor_0_used    = stats[2].to_f
    survivor_1_used    = stats[3].to_f
    eden_capacity      = stats[4].to_f
    eden_used          = stats[5].to_f
    old_capacity       = stats[6].to_f
    old_used           = stats[7].to_f
    permanent_capacity = stats[8].to_f
    permanent_used     = stats[9].to_f
    young_gc_count     = stats[10].to_f
    young_gc_time      = stats[11].to_f
    full_gc_count      = stats[12].to_f
    full_gc_time       = stats[13].to_f
    total_gc_time      = stats[14].to_f

    survivor_0_free = surivor_0_capacity - survivor_0_used
    survivor_1_free = surivor_1_capacity - survivor_1_used
    eden_free       = eden_capacity      - eden_used
    old_free        = old_capacity       - old_used
    permanent_free  = permanent_capacity - permanent_used

    report({
            "#{name_prefix} surivor 0 capacity".lstrip => surivor_0_capacity,
            "#{name_prefix} surivor 1 capacity".lstrip => surivor_1_capacity,
            "#{name_prefix} survivor 0 used".lstrip    => survivor_0_used,
            "#{name_prefix} survivor 1 used".lstrip    => survivor_1_used,
            "#{name_prefix} eden capacity".lstrip      => eden_capacity,
            "#{name_prefix} eden used".lstrip          => eden_used,
            "#{name_prefix} old capacity".lstrip       => old_capacity,
            "#{name_prefix} old used".lstrip           => old_used,
            "#{name_prefix} permanent capacity".lstrip => permanent_capacity,
            "#{name_prefix} permanant used".lstrip     => permanent_used,
            "#{name_prefix} young gc count".lstrip     => young_gc_count,
            "#{name_prefix} young gc time".lstrip      => young_gc_time,
            "#{name_prefix} full gc count".lstrip      => full_gc_count,
            "#{name_prefix} full gc time".lstrip       => full_gc_time,
            "#{name_prefix} total gc time".lstrip      => total_gc_time,
           } )
  end
end