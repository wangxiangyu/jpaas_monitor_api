$:.unshift(File.expand_path(".", File.dirname(__FILE__)))
require "config"
require "active_record"

class ApiDb < ActiveRecord::Base
    self.abstract_class = true
    self.establish_connection(
	    :adapter => "mysql",
	    :host =>MyConfig.mysql_host,
	    :database =>MyConfig.mysql_dbname,
	    :username =>MyConfig.mysql_user,
	    :password =>MyConfig.mysql_passwd,
        :port => MyConfig.mysql_port,
        :pool => 10,
        :reconnect => true
    )
end

class InstanceStatus < ApiDb
	self.table_name="instance_status"
end

class LogMonitorRaw < ApiDb
	self.table_name="log_monitor_raw"
end

class LogMonitorItem < ApiDb
	self.table_name="log_monitor_item"
end

class LogMonitorRule < ApiDb
	self.table_name="log_monitor_rule"
end

class LogMonitorAlert < ApiDb
	self.table_name="log_monitor_alarm"
end

class AppBns < ApiDb
	self.table_name="app_bns"
end

class UserDefinedMonitorRaw < ApiDb
	self.table_name="user_defined_monitor_raw"
end
class UserDefinedMonitorRule < ApiDb
	self.table_name="user_defined_monitor_rule"
end
class UserDefinedMonitorAlert < ApiDb
	self.table_name="user_defined_monitor_alarm"
end

class ProcMonitorRaw < ApiDb
	self.table_name="proc_monitor_raw"
end
class ProcMonitorRule < ApiDb
	self.table_name="proc_monitor_rule"
end
class ProcMonitorAlert < ApiDb
	self.table_name="proc_monitor_alarm"
end
class DeaList < ApiDb
    self.table_name="dea_list"
end

class DomainMonitorRaw < ApiDb
	self.table_name="domain_monitor_raw"
end
class DomainMonitorItem < ApiDb
	self.table_name="domain_monitor_item"
end
class DomainMonitorRule < ApiDb
	self.table_name="domain_monitor_rule"
end
class DomainMonitorAlert < ApiDb
	self.table_name="domain_monitor_alarm"
end
class HttpUserDefinedMonitorRaw < ApiDb
	self.table_name="http_user_defined_monitor_raw"
end
class HttpUserDefinedMonitorRule < ApiDb
	self.table_name="http_user_defined_monitor_rule"
end
class HttpUserDefinedMonitorAlert < ApiDb
	self.table_name="http_user_defined_monitor_alarm"
end

class ClusterDb < ActiveRecord::Base
    self.abstract_class = true
    self.establish_connection(
	    :adapter => "mysql",
	    :host =>MyConfig.mysql_cluster_host,
	    :database =>MyConfig.mysql_cluster_dbname,
	    :username =>MyConfig.mysql_cluster_user,
	    :password =>MyConfig.mysql_cluster_passwd,
        :port => MyConfig.mysql_cluster_port,
        :pool => 10,
        :reconnect => true
    )
end

class AllHosts < ClusterDb
    self.table_name="all_hosts"
end
