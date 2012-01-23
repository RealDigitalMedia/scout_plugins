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
    hash = get_latest_status

    media_player = hash["GatewayStatus"]["ActivityManager"]["Activities"]["MediaPlayer"]

    activity = option(:activity)

    report("#{activity} pending"     => media_player[activity]["Pending"].to_i)
    report("#{activity} complete"    => media_player[activity]["Complete"].to_i)
    report("#{activity} in progress" => media_player[activity]["InProgress"].to_i)
    report("#{activity} grand total" => media_player[activity]["Total"].to_i)
    counter("#{activity} total", media_player[activity]["Total"].to_i, :per => :minute)
  end

  protected

  def get_latest_status
    url = option(:url) || "http://localhost:9999/player/GatewayStatus.cfc"

    if cache_file_age < Time.now - 60
      status = open(url).read.gsub("\t", ' ').gsub('=',': ')
      File.open(cache_file, "w") { |file| file.write(status) }

      YAML::load(status)
    end

    YAML::load(File.read(cache_file))
  end

  def cache_file_age
    File.exist?(cache_file) ? File.stat(cache_file).mtime : Time.at(0)
  end

  def cache_file
    "/tmp/scout_gateway_status.txt"
  end
end
