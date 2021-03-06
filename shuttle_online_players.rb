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

class GatewayStatus < Scout::Plugin
  def build_report
    online = Player.joins(:customer).merge(Customer.where(:name => "shuttlecomputer")).online

    report("online" => online.count)
  end
end
