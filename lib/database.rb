$:.unshift(File.expand_path(".", File.dirname(__FILE__)))
require "config"
require "active_record"
ActiveRecord::Base.establish_connection(
	:adapter => "mysql",
#	:host =>Config.mysql_host,
#	:database =>Config.mysql_db_name,
#	:username =>Config.mysql_username,
#	:password =>Config.mysql_password
	:host =>"10.36.63.68",
	:database =>"jpaas",
	:username =>"jpaas",
	:password =>"mhxzkhl"
)
class InstanceStatus < ActiveRecord::Base
	self.table_name="instance_status"
end

class LogMonitorRaw < ActiveRecord::Base
	self.table_name="log_monitor_raw"
end

class LogMonitorItem < ActiveRecord::Base
	self.table_name="log_monitor_item"
end

class LogMonitorRule < ActiveRecord::Base
	self.table_name="log_monitor_rule"
end

class MonitorAlert < ActiveRecord::Base
	self.table_name="monitor_alarm"
end

class AppBns < ActiveRecord::Base
	self.table_name="app_bns"
end
