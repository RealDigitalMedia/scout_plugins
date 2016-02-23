class InterruptsContextSwitches < Scout::Plugin
  def build_report
    interrupts       = 0
    context_switches = 0
    File.readlines("/proc/stat").each do |line|
      data = line.split
      interrupts       = data[1].to_i if data[0] == "intr"
      context_switches = data[1].to_i if data[0] == "ctxt"
    end

    counter("interrupts", interrupts, :per => :second)
    counter("context switches", context_switches, :per => :second)
  end
end