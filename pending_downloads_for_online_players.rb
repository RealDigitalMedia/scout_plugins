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

class PendingDownloadsForOnlinePlayers < Scout::Plugin
  def build_report
    online = Player.joins(:customer).where("customers.name not in (?)", ["production"]).online

    report("pending_downloads_total_byte_count" => online.sum(:pending_downloads_total_byte_count),
           "pending_downloads_total_file_count" => online.sum(:pending_downloads_total_file_count))
  end
end