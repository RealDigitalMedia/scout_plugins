class NTPOffset < Scout::Plugin
  def build_report
    ntp_data = `ntpq -n -p | grep '^[*o]'`.split

    delay  = ntp_data[7].to_f
    offset = ntp_data[8].to_f
    jitter = ntp_data[9].to_f

    report("ntp delay"  => delay,
           "ntp offset" => offset,
           "ntp jitter" => jitter)
  end
end
