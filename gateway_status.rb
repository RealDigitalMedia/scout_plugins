require 'yaml'
require 'open-uri'

require 'open-uri'

class GatewayStatus < Scout::Plugin
  OPTIONS=<<-EOS
  url:
    name: Status URL
    default: "http://localhost/player/GatewayStatus.cfc"
  activity:
    name: Type of activity
  EOS

  def build_report
    activity = option(:activity)

    hash = get_latest_status

    media_player = hash.fetch("GatewayStatus", {}).
                        fetch("ActivityManager", {}).
                        fetch("Activities", {}).
                        fetch("MediaPlayer", {}).
                        fetch(activity, {})

    report("#{activity} pending"     => media_player["Pending"].to_i)
    report("#{activity} complete"    => media_player["Complete"].to_i)
    report("#{activity} in progress" => media_player["InProgress"].to_i)
    report("#{activity} grand total" => media_player["Total"].to_i)
    counter("#{activity} total", media_player["Total"].to_i, :per => :minute)
  end

  protected

  def get_latest_status
    url = option(:url) || "http://localhost:9999/player/GatewayStatus.cfc"

    if cache_file_age < Time.now - 60
      status = open(url, { "X-Forwarded-Proto" => "https" }).read.gsub("\t", ' ').gsub('=',': ')
      File.open(cache_file, "w") { |file| file.write(status) }
    end

    YAML::load(File.read(cache_file)) || {}
  rescue OpenURI::HTTPError, Errno::ENOENT
    {}
  end

  def cache_file_age
    File.exist?(cache_file) ? File.stat(cache_file).mtime : Time.at(0)
  end

  def cache_file
    "/tmp/scout_gateway_status.txt"
  end
end