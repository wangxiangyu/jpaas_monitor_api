$:.unshift(File.expand_path(".", File.dirname(__FILE__)))
require "config"
require "active_record"
ActiveRecord::Base.establish_connection(
	:adapter => "mysql",
	:host =>MyConfig.mysql_host,
	:database =>MyConfig.mysql_dbname,
	:username =>MyConfig.mysql_user,
	:password =>MyConfig.mysql_passwd,
    :port => MyConfig.mysql_port
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

class LogMonitorAlert < ActiveRecord::Base
	self.table_name="log_monitor_alarm"
end

class AppBns < ActiveRecord::Base
	self.table_name="app_bns"
end

class UserDefinedMonitorRaw < ActiveRecord::Base
	self.table_name="user_defined_monitor_raw"
end
class UserDefinedMonitorRule < ActiveRecord::Base
	self.table_name="user_defined_monitor_rule"
end
class UserDefinedMonitorAlert < ActiveRecord::Base
	self.table_name="user_defined_monitor_alarm"
end
