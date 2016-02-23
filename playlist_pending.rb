require 'rubygems'
require 'active_record'
require 'yaml'

require 'activerecord-jdbc-adapter' if defined? JRUBY_VERSION

dbconfig = YAML::load(File.open('/NEOCAST/etc/database.yml'))["production"]
ActiveRecord::Base.establish_connection(dbconfig)

ActiveRecord::Base.default_timezone = :local

begin
  class Player < ActiveRecord::Base
    belongs_to :customer

    def self.online
      where("(last_seen >= ?)", Time.now - 60.minutes)
    end
  end

  class Customer < ActiveRecord::Base
  end
rescue
  # Nothing to do, might be database connection issue
end

class PlaylistPendingCount < Scout::Plugin
  def build_report
    pending_on_demand = Player.online.where(:on_demand_needs_refresh => true).count
    pending_playlist  = Player.online.where(:playlist_needs_refresh => true).count
    pending_download  = Player.online.where(:needs_presentation_json_download => true).count
    late_content_sync = Player.online.where("last_synchronized_content_servertime < ?", 1.hour.ago).count

    report("pending_playlist" => pending_playlist,
           "pending_download" => pending_download,
           "pending_on_demand" => pending_on_demand,
           "late_content_sync" => late_content_sync)
  end
end