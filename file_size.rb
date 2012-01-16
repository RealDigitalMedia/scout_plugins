class FileSize < Scout::Plugin
  OPTIONS=<<-EOS
  path:
    name: File Path
  EOS

  def build_report
    path = option(:path)

    report("size"  => File.size(path))
  end
end
