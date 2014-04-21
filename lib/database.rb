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

class ProcMonitorRaw < ActiveRecord::Base
	self.table_name="proc_monitor_raw"
end
class ProcMonitorRule < ActiveRecord::Base
	self.table_name="proc_monitor_rule"
end
class ProcMonitorAlert < ActiveRecord::Base
	self.table_name="proc_monitor_alarm"
end
class DeaList < ActiveRecord::Base
    self.table_name="dea_list"
end

class DomainMonitorRaw < ActiveRecord::Base
	self.table_name="domain_monitor_raw"
end
class DomainMonitorItem < ActiveRecord::Base
	self.table_name="domain_monitor_item"
end
class DomainMonitorRule < ActiveRecord::Base
	self.table_name="domain_monitor_rule"
end
class DomainMonitorAlert < ActiveRecord::Base
	self.table_name="domain_monitor_alarm"
end
class HttpUserDefinedMonitorRaw < ActiveRecord::Base
	self.table_name="http_user_defined_monitor_raw"
end
class HttpUserDefinedMonitorRule < ActiveRecord::Base
	self.table_name="http_user_defined_monitor_rule"
end
class HttpUserDefinedMonitorAlert < ActiveRecord::Base
	self.table_name="http_user_defined_monitor_alarm"
end
