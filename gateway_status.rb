require 'yaml'
require 'open-uri'

require 'open-uri'

class GatewayStatus < Scout::Plugin
  OPTIONS=<<-EOS
  url:
    name: Status URL
    default: "http://127.0.0.1/player/GatewayStatus.cfc"
  EOS

  def build_report
    url = option(:url) || "http://localhost:9999/player/GatewayStatus.cfc"

    request_start = Time.now
    hash = YAML::load(open(url).read.gsub("\t", ' ').gsub('=',': '))
    request_end = Time.now

    media_player = hash["GatewayStatus"]["ActivityManager"]["Activities"]["MediaPlayer"]

    activities = %w{Housekeeping RetrieveCapabilities SynchronizeContentWithoutComputation FirmwareUpdate SynchronizeContent SynchronizeConfiguration RetrieveStatus ProcessUnknownTasks}

    report("query time" => request_end - request_start)

    activities.each do |activity|
      report("#{activity} pending" => media_player[activity]["Pending"].to_i)
      report("#{activity} complete" => media_player[activity]["Complete"].to_i)
      report("#{activity} in progress" => media_player[activity]["InProgress"].to_i)
      counter("Total", media_player[activity]["Total"].to_i, :per => :minute)
    end
  end
end

