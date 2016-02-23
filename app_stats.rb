require 'json'
require 'open-uri'

class AppStats < Scout::Plugin
  OPTIONS=<<-EOS
  url:
    name: Status URL
    default: "http://localhost/AWCRP/app_stats"
  EOS

  def build_report
    url = option(:url) || "http://localhost/AWCRP/app_stats"

    data = JSON.parse(open(url).read)

    report(Hash[data["ruby"]["object_space"]])
  end
end