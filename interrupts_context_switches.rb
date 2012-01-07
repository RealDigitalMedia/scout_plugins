class InterruptsContextSwitches < Scout::Plugin
  def build_report
    interrupts       = 0
    context_switches = 0
    File.readlines("/proc/stat").each do |line|
      data = line.split
      interrupts       = data[1].to_i if data[0] == "intr"
      context_switches = data[1].to_i if data[0] == "ctxt"
    end

    report({
            "interrupts"  => interrupts,
            "context switches" => context_switches,
           })
  end
end