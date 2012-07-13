class MountMonitor < Scout::Plugin
  OPTIONS = <<-EOS
  mountpoint:
    name: path to the mount point to monitor
    notes: The full path found in /etc/fstab for the mountpoint
  EOS

  def build_report
    lines = `mount`.split("\n")

    mounted = lines.any? { |line| option("mountpoint") == line.split[2] }

    report("mounted" => mounted ? 1 : 0)
  end
end

