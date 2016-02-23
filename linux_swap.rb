class LinuxSwap < Scout::Plugin
  def build_report
    case
      when File.exists?("/proc/vmstat") then
        # Example:
        # pswpin 151910346
        # pswpout 115152096
        swap_data = File.read("/proc/vmstat").split("\n").inject({}) { |hash,line| data = line.split; hash[data[0]] = data[1].to_i; hash }
        swap_in   = swap_data["pswpin"]
        swap_out  = swap_data["pswpout"]
      when File.exists?("/proc/swap") then
        # Example:
        # swap 28914 15951
        swap_data = File.read("/proc/stat").split
        swap_in   = swap_data[1]
        swap_out  = swap_data[2]
      else
        raise "No /proc/vmstat or /proc/swap files found"
    end

    report({
            "swap in"  => swap_in,
            "swap out" => swap_out,
           })
  end
end