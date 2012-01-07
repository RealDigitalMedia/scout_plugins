class NFSClient < Scout::Plugin

  def build_report
    nfs_proc_file = "/proc/net/rpc/nfs"

    attributes = %w{getattr setattr lookup access readlink read write create mkdir symlink mknod remove rmdir rename link readdir readdirplus fsstat fsinfo pathconf commit}

    raw_data = File.readlines(nfs_proc_file).find { |line| line.split[0] == "proc3" }.split

    data = {}
    attributes.each_with_index do |attribute, index|
      data[attribute] = raw_data[index + 3].to_i
    end

    report(data)
  end
end