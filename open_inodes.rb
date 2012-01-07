class OpenInodes < Scout::Plugin

  def build_report
    inode_nr = File.read("/proc/sys/fs/inode-nr").split.map { |value| value.to_i }

    max  = inode_nr[0]
    free = inode_nr[1]
    used = max - free

    report({
            "inodes max"  => max,
            "inodes free" => free,
            "inodes used" => used,
           })
  end
end